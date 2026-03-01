class Quiz < ApplicationRecord
  belongs_to :material
  has_many :quiz_attempts, dependent: :destroy

  validates :title, presence: true
  validates :questions, presence: true

  scope :recent, -> { order(created_at: :desc) }
end
