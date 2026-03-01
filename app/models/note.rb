class Note < ApplicationRecord
  belongs_to :material

  validates :title, :content, presence: true

  scope :recent, -> { order(created_at: :desc) }

  before_create :assign_share_token

  def summary
    data["summary"].to_s
  end

  def key_concepts
    Array(data["key_concepts"])
  end

  def practice_questions
    Array(data["practice_questions"])
  end

  def glossary
    Array(data["glossary"])
  end

  def public_share!
    update!(shared_public: true, share_token: share_token.presence || SecureRandom.hex(10))
  end

  def private_share!
    update!(shared_public: false)
  end

  private

  def assign_share_token
    self.share_token ||= SecureRandom.hex(10)
  end
end
