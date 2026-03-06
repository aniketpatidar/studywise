class QuizAttempt < ApplicationRecord
  belongs_to :quiz
  belongs_to :user

  validates :total, numericality: { greater_than_or_equal_to: 0 }
  validates :score, numericality: { greater_than_or_equal_to: 0 }
  validates :user_id, uniqueness: { scope: :quiz_id }
end
