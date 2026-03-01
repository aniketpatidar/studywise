module Study
  class NoteGenerationService
    class GenerationError < StandardError; end

    def initialize(material:)
      @material = material
    end

    def call
      extracted = source_content
      raise GenerationError, "Material content is missing." if extracted.blank?

      generated = structured_note_payload(extracted)

      Note.create!(
        material: @material,
        title: "Smart Note: #{@material.title}",
        content: render_note(generated[:data], generated[:mode]),
        data: generated[:data],
        generation_mode: generated[:mode]
      ).tap do
        @material.processed!
      end
    rescue ActiveRecord::RecordInvalid => e
      raise GenerationError, "Could not generate note: #{e.record.errors.full_messages.to_sentence}"
    end

    private

    def source_content
      @source_content ||= Study::ContentExtractionService.new(material: @material).call
    rescue Study::ContentExtractionService::ExtractionError => e
      raise GenerationError, e.message
    end

    def structured_note_payload(extracted)
      client = Study::GeminiClient.new
      prompt = <<~PROMPT
        You are StudyWISE.
        {
          "summary": "string",
          "key_concepts": ["string", "..."],
          "practice_questions": ["string", "..."],
          "glossary": [{"term":"string","definition":"string"}]
        }

        Material title: #{@material.title}
        Source type: #{@material.source_type}
        Content:
        #{extracted.first(12_000)}
      PROMPT

      response = client.ask(
        prompt,
        metadata: {
          operation: "note_generation",
          user_id: @material.user_id,
          material_id: @material.id
        }
      )
      parsed = JSON.parse(response)

      { data: normalized_payload(parsed), mode: "gemini" }
    rescue Study::GeminiClient::ConfigurationError, Study::GeminiClient::RequestError => e
      { data: build_fallback_data(error_message: e.message), mode: "fallback" }
    rescue JSON::ParserError
      { data: build_fallback_data(error_message: "Gemini returned non-JSON output."), mode: "fallback" }
    end

    def normalized_payload(payload)
      {
        "summary" => payload["summary"].to_s.strip,
        "key_concepts" => Array(payload["key_concepts"]).map(&:to_s).reject(&:blank?).first(10),
        "practice_questions" => Array(payload["practice_questions"]).map(&:to_s).reject(&:blank?).first(8),
        "glossary" => Array(payload["glossary"]).first(8).map do |entry|
          next unless entry.is_a?(Hash)

          {
            "term" => entry["term"].to_s,
            "definition" => entry["definition"].to_s
          }
        end.compact
      }
    end

    def build_fallback_data(error_message: nil)
      {
        "summary" => [
          "This is the StudyWISE local fallback summary.",
          error_message.present? ? "Gemini call failed: #{error_message}" : nil,
          source_content.first(300)
        ].compact.join(" "),
        "key_concepts" => source_content.scan(/[A-Z][A-Za-z0-9\- ]{4,40}/).uniq.first(6),
        "practice_questions" => [
          "What are the three most important ideas from this material?",
          "How would you explain this topic to a beginner?",
          "What part of this topic needs revision?"
        ],
        "glossary" => []
      }
    end

    def render_note(data, mode)
      lines = []
      lines << "Generation Mode: #{mode}"
      lines << ""
      lines << "Summary"
      lines << data["summary"].to_s
      lines << ""
      lines << "Key Concepts"
      Array(data["key_concepts"]).each { |item| lines << "- #{item}" }
      lines << ""
      lines << "Practice Questions"
      Array(data["practice_questions"]).each_with_index { |item, idx| lines << "#{idx + 1}. #{item}" }
      if Array(data["glossary"]).any?
        lines << ""
        lines << "Glossary"
        Array(data["glossary"]).each { |g| lines << "- #{g["term"]}: #{g["definition"]}" }
      end
      lines.join("\n")
    end
  end
end
