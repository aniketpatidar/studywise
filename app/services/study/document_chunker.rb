module Study
  class DocumentChunker
    def self.chunk_text(text, chunk_size: 1200, overlap: 200)
      normalized = text.to_s.gsub(/\s+/, " ").strip
      return [] if normalized.empty?

      chunks = []
      pointer = 0
      while pointer < normalized.length
        chunk = normalized[pointer, chunk_size]
        break unless chunk
        trimmed = chunk.strip
        chunks << {
          text: trimmed,
          summary: trimmed[0, 200]
        }
        pointer += chunk_size - overlap
      end
      chunks
    end
  end
end
