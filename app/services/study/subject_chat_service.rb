module Study
  class SubjectChatService
    PERSONAS = {
      "math" => "You are a rigorous math tutor. Show steps and check assumptions.",
      "physics" => "You are a physics tutor. Explain with intuition and equations.",
      "biology" => "You are a biology tutor. Use clear definitions and examples.",
      "history" => "You are a history tutor. Ground answers in chronology and causality."
    }.freeze

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
      subject = @chat_session.subject_name.to_s
      persona = PERSONAS.fetch(subject.downcase, "You are a helpful academic tutor.")
      model = ENV.fetch("GEMINI_MODEL", "gemini-2.0-flash")
      key = ENV["GEMINI_API_KEY"].to_s
      raise Study::GeminiClient::ConfigurationError, "GEMINI_API_KEY is missing." if key.blank?

      context = RubyLLM.context { |config| config.gemini_api_key = key }
      chat = context.chat(model:, provider: :gemini, assume_model_exists: true)
      chat.with_instructions(<<~INSTRUCTIONS)
        #{persona}
        Use tools for targeted practice when useful.
        Keep your response concise and practical for students.
      INSTRUCTIONS
      chat.with_tool(Study::Tools::SubjectPracticeTool.new)
      response = chat.ask("Subject: #{subject}\nQuestion: #{@user_message}").content.to_s
      Study::LlmEventLogger.log!(
        user_id: @chat_session.user_id,
        material_id: nil,
        provider: "gemini",
        model: model,
        operation: "subject_chat",
        success: true,
        status_code: 200,
        prompt_chars: @user_message.length,
        response_chars: response.length,
        latency_ms: nil
      )
      response.presence || "I've analyzed your question. How else can I help you with #{subject} today?"
    rescue StandardError => e
      Study::LlmEventLogger.log!(
        user_id: @chat_session.user_id,
        material_id: nil,
        provider: "gemini",
        model: ENV.fetch("GEMINI_MODEL", "gemini-2.0-flash"),
        operation: "subject_chat",
        success: false,
        status_code: nil,
        prompt_chars: @user_message.length,
        response_chars: 0,
        latency_ms: nil,
        error_message: e.message
      )
      "Subject chat fallback response (#{e.class}): Start by breaking the topic into 3 core concepts and test yourself after each."
    end
  end
end
