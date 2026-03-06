require "ruby_llm"

module Study
  class GeminiClient
    class ConfigurationError < StandardError; end
    class RequestError < StandardError; end

    def initialize(api_key: ENV["GEMINI_API_KEY"], model: ENV.fetch("GEMINI_MODEL", "gemini-2.0-flash"))
      @api_key = api_key
      @model = model
      @max_retries = ENV.fetch("GEMINI_MAX_RETRIES", "2").to_i
      raise ConfigurationError, "GEMINI_API_KEY is missing." if @api_key.blank?
    end

    def generate_study_note(title:, source_type:, content:, metadata: {})
      prompt = <<~PROMPT
        You are StudyWISE. Generate concise study notes.
        Return plain text with sections:
        Summary
        Key Concepts
        Practice Questions
        Glossary

        Material title: #{title}
        Source type: #{source_type}
        Content:
        #{content.first(12_000)}
      PROMPT

      ask(prompt, metadata:)
    end

    def ask(prompt, metadata: {})
      started_at = Process.clock_gettime(Process::CLOCK_MONOTONIC)
      context = RubyLLM.context do |config|
        config.gemini_api_key = @api_key
      end

      generated = with_retries do
        response = context.chat(model: @model, provider: :gemini, assume_model_exists: true).ask(prompt)
        response.content.to_s
      end

      raise RequestError, "Gemini returned an empty response (model: #{@model})." if generated.blank?

      log_event(
        metadata:,
        operation: metadata[:operation] || "ask",
        success: true,
        status_code: 200,
        prompt_chars: prompt.to_s.length,
        response_chars: generated.length,
        latency_ms: elapsed_ms(started_at),
        prompt_preview: prompt,
        response_preview: generated
      )

      generated
    rescue RubyLLM::ConfigurationError => e
      log_event(metadata:, operation: metadata[:operation] || "ask", success: false, status_code: nil,
                prompt_chars: prompt.to_s.length, response_chars: 0, latency_ms: elapsed_ms(started_at),
                error_message: e.message, prompt_preview: prompt)
      raise ConfigurationError, e.message
    rescue RubyLLM::Error, RubyLLM::ModelNotFoundError => e
      status = e.respond_to?(:response) && e.response ? e.response.status : nil
      detail = status ? "status=#{status}" : "no_status"
      log_event(metadata:, operation: metadata[:operation] || "ask", success: false, status_code: status,
                prompt_chars: prompt.to_s.length, response_chars: 0, latency_ms: elapsed_ms(started_at),
                error_message: e.message, prompt_preview: prompt)
      raise RequestError, "Gemini request failed via ruby_llm (#{detail}, model: #{@model}): #{e.message}"
    end

    def with_retries
      attempts = 0
      begin
        attempts += 1
        yield
      rescue RubyLLM::RateLimitError, RubyLLM::ServiceUnavailableError, RubyLLM::OverloadedError => e
        raise e if attempts > @max_retries

        sleep(0.8 * attempts)
        retry
      end
    end

    def elapsed_ms(started_at)
      ((Process.clock_gettime(Process::CLOCK_MONOTONIC) - started_at) * 1000).to_i
    end

    def log_event(metadata:, operation:, success:, status_code:, prompt_chars:, response_chars:, latency_ms:, error_message: nil, prompt_preview: nil, response_preview: nil)
      Study::LlmEventLogger.log!(
        user_id: metadata[:user_id],
        material_id: metadata[:material_id],
        provider: "gemini",
        model: @model,
        operation: operation,
        success: success,
        status_code: status_code,
        prompt_chars: prompt_chars,
        response_chars: response_chars,
        latency_ms: latency_ms,
        error_message: error_message,
        prompt_preview: prompt_preview,
        response_preview: response_preview
      )
    end
  end
end
