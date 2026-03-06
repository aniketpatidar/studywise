module Study
  class StudyChatService
    def initialize(chat_session:, user_message:)
      @chat_session = chat_session
      @user_message = user_message.to_s.strip
    end

    def call
      @chat_session.chat_messages.create!(role: "user", content: @user_message)
      assistant = generate_response
      @chat_session.chat_messages.create!(role: "assistant", content: assistant)
    end

    private

    def generate_response
      material = @chat_session.material
      model = ENV.fetch("GEMINI_MODEL", "gemini-2.0-flash")
      key = ENV["GEMINI_API_KEY"].to_s
      raise Study::GeminiClient::ConfigurationError, "GEMINI_API_KEY is missing." if key.blank?

      context = RubyLLM.context { |config| config.gemini_api_key = key }
      chat = context.chat(model:, provider: :gemini, assume_model_exists: true)
      chat.with_instructions(<<~INSTRUCTIONS)
        You are StudyWISE Study Chat.
        Use tools whenever needed to fetch note context and quiz history.
        Be concise, accurate, and educational.
      INSTRUCTIONS
      chat.with_tool(Study::Tools::MaterialContextTool.new(material: material))
      chat.with_tool(Study::Tools::QuizHistoryTool.new(user: @chat_session.user, material: material))
      response = chat.ask(@user_message).content.to_s
      Study::LlmEventLogger.log!(
        user_id: @chat_session.user_id,
        material_id: material.id,
        provider: "gemini",
        model: model,
        operation: "study_chat",
        success: true,
        status_code: 200,
        prompt_chars: @user_message.length,
        response_chars: response.length,
        latency_ms: nil
      )
      response.presence || "I've reviewed the material. Do you have any specific questions about it?"
    rescue StandardError => e
      Study::LlmEventLogger.log!(
        user_id: @chat_session.user_id,
        material_id: material.id,
        provider: "gemini",
        model: ENV.fetch("GEMINI_MODEL", "gemini-2.0-flash"),
        operation: "study_chat",
        success: false,
        status_code: nil,
        prompt_chars: @user_message.length,
        response_chars: 0,
        latency_ms: nil,
        error_message: e.message
      )
      context_note = material.notes.recent.first
      "I could not reach Gemini right now (#{e.class}). Based on current notes: #{context_note&.summary.to_s.first(260)}"
    end
  end
end
