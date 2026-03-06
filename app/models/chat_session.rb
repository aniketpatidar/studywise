class ChatSession < ApplicationRecord
  extend FriendlyId

  MODES = %w[study subject].freeze

  belongs_to :user
  belongs_to :material, optional: true
  has_many :chat_messages, dependent: :destroy

  validates :mode, inclusion: { in: MODES }
  validates :subject_name, presence: true, if: -> { mode == "subject" }

  scope :recent, -> { order(updated_at: :desc) }

  friendly_id :subject_name, use: :slugged

  def should_generate_new_friendly_id?
    mode == "subject" && (slug.blank? || will_save_change_to_subject_name?)
  end
end
