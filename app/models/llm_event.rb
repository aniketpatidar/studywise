class LlmEvent < ApplicationRecord
  belongs_to :user, optional: true
  belongs_to :material, optional: true

  validates :provider, :model, :operation, presence: true

  scope :recent, -> { order(created_at: :desc) }
end
