module Study
  module Tools
    class MaterialContextTool < RubyLLM::Tool
      description "Fetch grounded context from the current material and generated notes."
      param :topic, desc: "Optional topic keyword to focus the returned context.", required: false

      def initialize(material:)
        @material = material
      end

      def execute(topic: nil)
        note = @material.notes.recent.first
        return "No generated notes are available yet for this material." unless note

        summary = note.summary
        concepts = note.key_concepts
        questions = note.practice_questions
        excerpt = @material.raw_text.to_s.first(900)

        if topic.present?
          filtered = concepts.select { |c| c.downcase.include?(topic.downcase) }
          concepts = filtered if filtered.any?
        end

        [
          "Material: #{@material.title}",
          ("Summary: #{summary}" if summary.present?),
          ("Key Concepts: #{concepts.join(', ')}" if concepts.any?),
          ("Practice Questions: #{questions.first(3).join(' | ')}" if questions.any?),
          ("Source Excerpt: #{excerpt}" if excerpt.present?)
        ].compact.join("\n")
      end
    end
  end
end
