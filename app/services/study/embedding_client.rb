require "zlib"

module Study
  class EmbeddingClient
    VECTOR_SIZE = 64

    def embed(text)
      tokens = text.to_s.downcase.scan(/[a-z]{3,}/)
      counts = Array.new(VECTOR_SIZE, 0.0)
      tokens.each do |token|
        idx = Zlib.crc32(token) % VECTOR_SIZE
        counts[idx] += 1
      end
      normalize(counts)
    end

    def batch_embed(texts)
      texts.map { |text| embed(text) }
    end

    private

    def normalize(vector)
      sum = vector.sum
      return vector if sum.zero?
      vector.map { |value| value / sum }
    end
  end
end
