module Study
  class StudyChatService
    MEMORY_MODES = {
      "focused" => {
        label: "Focused",
        history_messages: 4,
        history_chars: 1_200,
        source_chars: 2_200,
        prompt_chars: 4_500
      },
      "balanced" => {
        label: "Balanced",
        history_messages: 8,
        history_chars: 2_400,
        source_chars: 3_200,
        prompt_chars: 6_800
      },
      "extended" => {
        label: "Extended",
        history_messages: 14,
        history_chars: 3_800,
        source_chars: 4_800,
        prompt_chars: 9_800
      }
    }.freeze

    def self.normalize_memory_mode(value)
      mode = value.to_s
      return mode if MEMORY_MODES.key?(mode)

      "balanced"
    end

    def self.memory_mode_options
      MEMORY_MODES.map { |key, cfg| [cfg[:label], key] }
    end

    def initialize(chat_session:, user_message:, memory_mode: "balanced", persist_user_message: true, persist_assistant_message: true, excluded_message_ids: [])
      @chat_session = chat_session
      @user_message = user_message.to_s.strip
      @memory_mode = self.class.normalize_memory_mode(memory_mode)
      @persist_user_message = persist_user_message
      @persist_assistant_message = persist_assistant_message
      @excluded_message_ids = Array(excluded_message_ids).map(&:to_i).uniq
    end

    def call
      @chat_session.chat_messages.create!(role: "user", content: @user_message) if @persist_user_message
      assistant = generate_response
      @chat_session.chat_messages.create!(role: "assistant", content: assistant) if @persist_assistant_message
      assistant
    end

    def stream
      @chat_session.chat_messages.create!(role: "user", content: @user_message) if @persist_user_message
      assistant = generate_response do |chunk|
        yield chunk if block_given?
      end
      @chat_session.chat_messages.create!(role: "assistant", content: assistant) if @persist_assistant_message
      assistant
    end

    private

    def generate_response
      material = @chat_session.material
      mode_cfg = MEMORY_MODES.fetch(@memory_mode)
      model = ENV.fetch("GEMINI_MODEL", "gemini-2.0-flash")
      key = ENV["GEMINI_API_KEY"].to_s
      raise Study::GeminiClient::ConfigurationError, "GEMINI_API_KEY is missing." if key.blank?

      context = RubyLLM.context { |config| config.gemini_api_key = key }
      chat = context.chat(model:, provider: :gemini, assume_model_exists: true)
      chat.with_instructions(<<~INSTRUCTIONS)
        You are StudyWISE Study Chat.
        Answer using the provided source context and conversation context.
        Keep responses concise, practical, and accurate.
        Use short bullet points for multi-step explanations.
      INSTRUCTIONS
      chat.with_tool(Study::Tools::MaterialContextTool.new(material: material))
      chat.with_tool(Study::Tools::QuizHistoryTool.new(user: @chat_session.user, material: material))
      chat.with_tool(Study::Tools::MaterialRetrievalTool.new(material: material))

      retrieval_context = Study::Tools::MaterialRetrievalTool.new(material: material).execute(question: @user_message)
      prompt = build_prompt(material:, mode_cfg:, retrieval_context:)
      response = stream_assistant_response(chat:, prompt:)
      response = "I've reviewed the material. Ask a narrower question and I can go deeper." if response.blank?
      response_with_citations = attach_citations(response, material)

      if block_given? && response_with_citations.start_with?(response)
        suffix = response_with_citations[response.length..]
        yield suffix if suffix.present?
      end

      Study::LlmEventLogger.log!(
        user_id: @chat_session.user_id,
        material_id: material.id,
        provider: "gemini",
        model: model,
        operation: "study_chat",
        success: true,
        status_code: 200,
        prompt_chars: prompt.length,
        response_chars: response_with_citations.length,
        latency_ms: nil,
        prompt_preview: prompt,
        response_preview: response_with_citations
      )
      response_with_citations
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
        error_message: e.message,
        prompt_preview: @user_message
      )
      context_note = material.notes.recent.first
      fallback = "I could not reach Gemini right now (#{e.class}). Based on current notes: #{context_note&.summary.to_s.first(260)}"
      yield fallback if block_given?
      fallback
    end

    def stream_assistant_response(chat:, prompt:)
      if block_given?
        streamed_content = +""
        message = chat.ask(prompt) do |chunk|
          piece = chunk.content.to_s
          next if piece.blank?

          streamed_content << piece
          yield piece
        end
        response = message.content.to_s.strip
        response = streamed_content.strip if response.blank?
        response
      else
        chat.ask(prompt).content.to_s.strip
      end
    end

    def build_prompt(material:, mode_cfg:, retrieval_context: nil)
      history_context = build_history_context(mode_cfg)
      source_context = build_source_context(material:, mode_cfg:)

      sections = [
        "Memory mode: #{@memory_mode}",
        ("Conversation context:\n#{history_context}" if history_context.present?),
        ("Source context:\n#{source_context}" if source_context.present?),
        ("Retrieved context:\n#{retrieval_context}" if retrieval_context.present?),
        "User question:\n#{@user_message}"
      ].compact

      sections.join("\n\n").first(mode_cfg[:prompt_chars])
    end

    def build_history_context(mode_cfg)
      all_messages = @chat_session.chat_messages.recent.to_a.reject { |msg| @excluded_message_ids.include?(msg.id) }
      all_messages = all_messages[0...-1] if @persist_user_message && all_messages.last&.role == "user"
      selected = all_messages.last(mode_cfg[:history_messages])
      omitted = all_messages.size - selected.size

      lines = selected.map { |msg| "#{msg.role.upcase}: #{sanitize_line(msg.content, 260)}" }
      lines.unshift("#{omitted} older messages omitted to keep context focused.") if omitted.positive?
      trim_lines(lines, mode_cfg[:history_chars])
    end

    def build_source_context(material:, mode_cfg:)
      note = material.notes.recent.first
      extracted = cached_source_content(material)

      chunks = []
      chunks << "Title: #{material.title}"
      chunks << "Note summary: #{sanitize_line(note.summary, 700)}" if note&.summary.present?
      if note&.key_concepts.to_a.any?
        chunks << "Key concepts: #{note.key_concepts.first(10).join(', ')}"
      end
      chunks << "Extracted source excerpt: #{sanitize_line(extracted, mode_cfg[:source_chars])}" if extracted.present?

      chunks.join("\n").first(mode_cfg[:source_chars])
    end

    def cached_source_content(material)
      cache_key = "study_chat:source:v1:material:#{material.id}:#{material.updated_at.to_i}"
      Rails.cache.fetch(cache_key, expires_in: 20.minutes) do
        Study::ContentExtractionService.new(material: material).call(max_chars: 8_000)
      rescue StandardError
        material.raw_text.to_s.first(8_000)
      end
    end

    def attach_citations(response, material)
      citations = build_citations(material)
      return response if citations.empty?

      [response, "", "Citations:", *citations.map { |line| "- #{line}" }].join("\n")
    end

    def build_citations(material)
      source = cached_source_content(material)
      return [] if source.blank?

      keywords = @user_message.downcase.scan(/[a-z]{4,}/).uniq.first(8)
      sentences = source.split(/(?<=[.!?])\s+/).map(&:strip).reject(&:blank?)
      return [] if sentences.empty?

      matches = if keywords.any?
        sentences.select { |sentence| keywords.any? { |term| sentence.downcase.include?(term) } }
      else
        []
      end
      matches = sentences.first(2) if matches.empty?

      matches.first(2).each_with_index.map do |snippet, idx|
        "[C#{idx + 1}] \"#{sanitize_line(snippet, 180)}\""
      end
    end

    def sanitize_line(value, max_len)
      value.to_s.gsub(/\s+/, " ").strip.first(max_len)
    end

    def trim_lines(lines, max_chars)
      return "" if lines.empty?

      result = []
      remaining = max_chars
      lines.each do |line|
        break if remaining <= 0

        clipped = line.first(remaining)
        result << clipped
        remaining -= clipped.length + 1
      end
      result.join("\n")
    end
  end
end
