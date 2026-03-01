module Study
  module Tools
    class SubjectPracticeTool < RubyLLM::Tool
      description "Generate concise practice tasks for a subject and topic."
      param :subject, desc: "Subject name like Math, Physics, Biology, History"
      param :topic, desc: "Optional topic to target", required: false

      def execute(subject:, topic: nil)
        core = topic.presence || "core foundations"
        case subject.to_s.downcase
        when "math"
          "Math practice for #{core}: 1) solve one equation, 2) explain each step, 3) verify with substitution."
        when "physics"
          "Physics practice for #{core}: 1) define variables, 2) pick governing equation, 3) compute units + final value."
        when "biology"
          "Biology practice for #{core}: 1) define the concept, 2) diagram process, 3) compare with related mechanism."
        when "history"
          "History practice for #{core}: 1) timeline, 2) causes, 3) consequences, 4) two-source comparison."
        else
          "Practice plan for #{subject} / #{core}: define, explain, apply, and self-test."
        end
      end
    end
  end
end
