module Study
  module Tools
    class QuizHistoryTool < RubyLLM::Tool
      description "Return recent quiz performance and mistakes for this material."

      def initialize(user:, material:)
        @user = user
        @material = material
      end

      def execute
        attempts = @material.quizzes.flat_map do |quiz|
          quiz.quiz_attempts.where(user: @user).order(created_at: :desc).limit(3)
        end
        return "No quiz attempts found for this material." if attempts.empty?

        rows = attempts.first(3).map do |attempt|
          "#{attempt.created_at.strftime('%Y-%m-%d %H:%M')} score=#{attempt.score}/#{attempt.total}"
        end

        "Recent quiz attempts:\n#{rows.join("\n")}"
      end
    end
  end
end
