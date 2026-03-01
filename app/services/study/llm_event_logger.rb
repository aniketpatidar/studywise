module Study
  class LlmEventLogger
    def self.log!(attributes)
      LlmEvent.create!(attributes)
    rescue StandardError => e
      Rails.logger.warn("LLM event logging skipped: #{e.class} #{e.message}")
    end
  end
end
