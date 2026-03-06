module Study
  class MaterialRetrievalIndex
    def self.build(material:, source_text:)
      return if source_text.to_s.strip.empty?

      chunks = DocumentChunker.chunk_text(source_text)
      return if chunks.empty?

      embeddings = EmbeddingClient.new.batch_embed(chunks.map { |chunk| chunk[:text] })

      MaterialChunk.transaction do
        material.material_chunks.delete_all
        chunks.each_with_index do |chunk, index|
          material.material_chunks.create!(
            sequence: index,
            chunk_text: chunk[:text],
            summary: chunk[:summary],
            embedding: embeddings[index]
          )
        end
      end
    end

    def self.fetch_relevant(material:, query:, limit: 3)
      return [] if query.to_s.strip.empty?

      query_vector = EmbeddingClient.new.embed(query)
      material.material_chunks.select(:chunk_text, :summary, :embedding).map do |chunk|
        {
          text: chunk.chunk_text,
          summary: chunk.summary,
          score: cosine_similarity(query_vector, chunk.normalized_embedding)
        }
      end.sort_by { |item| -item[:score] }.first(limit).reject { |item| item[:score].nil? || item[:score].zero? }
    end

    def self.cosine_similarity(vec1, vec2)
      return 0.0 if vec1.blank? || vec2.blank?
      dot = vec1.zip(vec2).map { |a, b| a.to_f * b.to_f }.sum
      norm1 = Math.sqrt(vec1.sum { |val| val**2 })
      norm2 = Math.sqrt(vec2.sum { |val| val**2 })
      return 0.0 if norm1.zero? || norm2.zero?
      dot / (norm1 * norm2)
    end
  end
end
