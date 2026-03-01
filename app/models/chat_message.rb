class ChatMessage < ApplicationRecord
  ROLES = %w[user assistant].freeze

  belongs_to :chat_session, touch: true

  validates :role, inclusion: { in: ROLES }
  validates :content, presence: true

  scope :recent, -> { order(created_at: :asc) }
end
