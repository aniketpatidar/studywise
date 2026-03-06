module Study
  module Tools
    class QuizValidationTool < RubyLLM::Tool
      description "Validate a quiz payload. Returns cleaned questions or raises a SchemaError."
      param :payload, desc: "Parsed JSON payload for quiz generation."

      def execute(payload:)
        validate_schema!(payload)
      end

      def validate_schema!(payload)
        questions = payload["questions"]
        raise SchemaError, "questions must be an array" unless questions.is_a?(Array)
        raise SchemaError, "must contain exactly 5 questions" unless questions.size == 5

        questions.map.with_index do |q, idx|
          raise SchemaError, "question #{idx + 1} is not an object" unless q.is_a?(Hash)

          question_text = q["question"].to_s.strip
          options = Array(q["options"]).map { |opt| opt.to_s.strip }
          answer_index = q["answer_index"]
          explanation = q["explanation"].to_s.strip

          raise SchemaError, "question #{idx + 1} text is blank" if question_text.blank?
          raise SchemaError, "question #{idx + 1} must have exactly 4 options" unless options.size == 4
          raise SchemaError, "question #{idx + 1} has blank options" if options.any?(&:blank?)
          raise SchemaError, "question #{idx + 1} options must be unique" unless options.uniq.size == 4
          raise SchemaError, "question #{idx + 1} explanation is blank" if explanation.blank?

          normalized_answer_index = Integer(answer_index)
          raise SchemaError, "question #{idx + 1} answer_index must be 0..3" unless normalized_answer_index.between?(0, 3)

          {
            "question" => question_text,
            "options" => options,
            "answer_index" => normalized_answer_index,
            "explanation" => explanation
          }
        rescue ArgumentError, TypeError
          raise SchemaError, "question #{idx + 1} answer_index must be an integer"
        end
      end

      class SchemaError < StandardError; end
    end
  end
end
