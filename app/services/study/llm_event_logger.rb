module Study
  class LlmEventLogger
    def self.log!(attributes)
      safe_attributes = normalize_attributes(attributes)
      LlmEvent.create!(safe_attributes)
    rescue StandardError => e
      Rails.logger.warn("LLM event logging skipped: #{e.class} #{e.message}")
    end

    def self.normalize_attributes(attributes)
      attrs = attributes.dup
      attrs[:prompt_preview] = compact_preview(attrs[:prompt_preview])
      attrs[:response_preview] = compact_preview(attrs[:response_preview])
      attrs
    end

    def self.compact_preview(value, limit = 2_000)
      value.to_s.gsub(/\s+/, " ").strip.first(limit).presence
    end
  end
end
