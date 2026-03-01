class ChatSession < ApplicationRecord
  MODES = %w[study subject].freeze

  belongs_to :user
  belongs_to :material, optional: true
  has_many :chat_messages, dependent: :destroy

  validates :mode, inclusion: { in: MODES }
  validates :subject_name, presence: true, if: -> { mode == "subject" }

  scope :recent, -> { order(updated_at: :desc) }
end
