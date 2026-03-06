class MaterialChunk < ApplicationRecord
  belongs_to :material

  validates :sequence, presence: true
  validates :chunk_text, presence: true
  validates :embedding, presence: true

  def normalized_embedding
    Array(embedding).map(&:to_f)
  end
end
