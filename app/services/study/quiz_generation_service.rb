module Study
  class QuizGenerationService
    class SchemaError < StandardError; end

    def initialize(material:, idempotency_key: nil)
      @material = material
      @idempotency_key = idempotency_key.to_s.presence
    end

    def call
      existing_quiz = find_existing_quiz
      return existing_quiz if existing_quiz

      generated = build_questions
      Quiz.create!(
        material: @material,
        title: "Quiz: #{@material.title}",
        questions: generated[:questions],
        generation_mode: generated[:mode],
        idempotency_key: @idempotency_key
      )
    end

    private

    def find_existing_quiz
      return if @idempotency_key.blank?

      @material.quizzes.find_by(idempotency_key: @idempotency_key)
    end

    def build_questions
      extracted = source_content
      prompt = <<~PROMPT
        Generate exactly 5 MCQs in valid JSON with shape:
        {
          "questions": [
            {
              "question": "string",
              "options": ["A", "B", "C", "D"],
              "answer_index": 0,
              "explanation": "string"
            }
          ]
        }

        Material:
        #{extracted.first(12_000)}
      PROMPT

      raw_response = Study::GeminiClient.new.ask(
        prompt,
        metadata: {
          operation: "quiz_generation",
          user_id: @material.user_id,
          material_id: @material.id
        }
      )
      parsed = parse_json_payload(raw_response)
      questions = Study::Tools::QuizValidationTool.new.execute(payload: parsed)
      { mode: "gemini", questions: questions }
    rescue JSON::ParserError, Study::GeminiClient::ConfigurationError, Study::GeminiClient::RequestError, Study::Tools::QuizValidationTool::SchemaError, Study::ContentExtractionService::ExtractionError
      fallback_questions
    end

    def source_content
      Study::ContentExtractionService.new(material: @material).call(max_chars: 16_000)
    end

    def validate_schema!(_payload)
      raise NotImplementedError, "Use Study::Tools::QuizValidationTool instead"
    end

    def parse_json_payload(raw_response)
      content = raw_response.to_s.strip
      return JSON.parse(content) if content.start_with?("{")

      if content.start_with?("```")
        content = content.sub(/\A```(?:json)?\s*/i, "").sub(/\s*```\z/, "").strip
        return JSON.parse(content)
      end

      json_start = content.index("{")
      json_end = content.rindex("}")
      if json_start && json_end && json_end > json_start
        candidate = content[json_start..json_end]
        return JSON.parse(candidate)
      end

      JSON.parse(content)
    end

    def fallback_questions
      extracted = source_content
      concepts = extracted
        .split(/[.!?\n]/)
        .map(&:strip)
        .reject(&:blank?)
        .first(8)
      concepts = @material.notes.recent.first&.key_concepts.to_a if concepts.empty?
      concepts = ["Core concept", "Definition", "Application", "Example", "Review"] if concepts.empty?

      base = concepts.first(5)
      base << "Key idea #{base.size + 1}" while base.size < 5

      questions = base.map do |concept|
        prompt_label = concept.first(80)
        {
          "question" => "Which statement best describes this idea: #{prompt_label}?",
          "options" => [
            "It is a core point from the source material.",
            "It is unrelated to the topic being studied.",
            "It only appears as historical trivia with no relevance.",
            "It is a formatting artifact and not a concept."
          ],
          "answer_index" => 0,
          "explanation" => "This idea appears in the extracted material and should be retained for revision."
        }
      end
      { mode: "fallback", questions: questions }
    rescue Study::ContentExtractionService::ExtractionError
      concepts = @material.notes.recent.first&.key_concepts.to_a
      concepts = ["Core concept", "Definition", "Application", "Example", "Review"] if concepts.empty?
      questions = concepts.first(5).map do |concept|
        {
          "question" => "Which statement best describes this idea: #{concept.to_s.first(80)}?",
          "options" => [
            "It is a core point from the source material.",
            "It is unrelated to the topic being studied.",
            "It only appears as historical trivia with no relevance.",
            "It is a formatting artifact and not a concept."
          ],
          "answer_index" => 0,
          "explanation" => "This idea is identified as important for revision."
        }
      end
      questions << {
        "question" => "Which statement best describes this idea: Key idea #{questions.size + 1}?",
        "options" => [
          "It is a core point from the source material.",
          "It is unrelated to the topic being studied.",
          "It only appears as historical trivia with no relevance.",
          "It is a formatting artifact and not a concept."
        ],
        "answer_index" => 0,
        "explanation" => "This idea is identified as important for revision."
      } while questions.size < 5
      { mode: "fallback", questions: questions.first(5) }
    end
  end
end
