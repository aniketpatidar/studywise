class User < ApplicationRecord
  has_secure_password

  has_many :materials, dependent: :destroy
  has_many :chat_sessions, dependent: :destroy
  has_many :quiz_attempts, dependent: :destroy
  has_many :llm_events, dependent: :nullify

  before_validation :normalize_email

  validates :name, presence: true
  validates :email, presence: true, uniqueness: { case_sensitive: false }
  validates :oauth_uid, uniqueness: { scope: :oauth_provider }, allow_blank: true

  private

  def normalize_email
    self.email = email.to_s.downcase.strip
  end
end
