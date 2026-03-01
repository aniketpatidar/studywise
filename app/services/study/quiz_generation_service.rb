module Study
  class QuizGenerationService
    def initialize(material:)
      @material = material
    end

    def call
      generated = build_questions
      Quiz.create!(
        material: @material,
        title: "Quiz: #{@material.title}",
        questions: generated[:questions],
        generation_mode: generated[:mode]
      )
    end

    private

    def build_questions
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
        #{@material.notes.recent.first&.content.to_s.first(10_000)}
      PROMPT

      parsed = JSON.parse(
        Study::GeminiClient.new.ask(
          prompt,
          metadata: {
            operation: "quiz_generation",
            user_id: @material.user_id,
            material_id: @material.id
          }
        )
      )
      questions = Array(parsed["questions"]).map do |q|
        next unless q.is_a?(Hash)

        {
          "question" => q["question"].to_s,
          "options" => Array(q["options"]).map(&:to_s).first(4),
          "answer_index" => q["answer_index"].to_i,
          "explanation" => q["explanation"].to_s
        }
      end.compact
      return { mode: "gemini", questions: questions } if questions.any?

      fallback_questions
    rescue StandardError
      fallback_questions
    end

    def fallback_questions
      concepts = @material.notes.recent.first&.key_concepts.to_a
      concepts = ["Core concept", "Definition", "Application"] if concepts.empty?
      questions = concepts.first(3).map do |concept|
        {
          "question" => "Which statement best describes #{concept}?",
          "options" => [
            "#{concept} is central to the material.",
            "#{concept} is unrelated to the topic.",
            "#{concept} is only historical trivia.",
            "#{concept} has no practical use."
          ],
          "answer_index" => 0,
          "explanation" => "#{concept} appears as a key concept in the note."
        }
      end
      { mode: "fallback", questions: questions }
    end
  end
end
