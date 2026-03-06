class Material < ApplicationRecord
  extend FriendlyId
  SOURCE_TYPES = %w[text pdf docx pptx youtube].freeze
  SUPPORTED_FILE_EXTENSIONS = %w[.pdf .txt .md .docx .pptx].freeze
  MAX_SOURCE_FILE_SIZE = 50.megabytes

  belongs_to :user
  has_many :notes, dependent: :destroy
  has_many :chat_sessions, dependent: :destroy
  has_many :quizzes, dependent: :destroy
  has_many :llm_events, dependent: :nullify
  has_many :material_chunks, dependent: :delete_all
  has_one_attached :source_file

  enum :status, { pending: 0, processing: 1, processed: 2, failed: 3 }, default: :pending
  friendly_id :title, use: :slugged

  validates :title, presence: true
  validates :source_type, inclusion: { in: SOURCE_TYPES }
  validates :raw_text, presence: true, if: -> { source_type == "text" && source_file.blank? }
  validates :source_url, presence: true, if: -> { source_type == "youtube" }
  validate :source_file_constraints

  scope :recent, -> { order(created_at: :desc) }

  private

  def source_file_constraints
    return unless source_file.attached?

    extension = File.extname(source_file.filename.to_s).downcase
    unless SUPPORTED_FILE_EXTENSIONS.include?(extension)
      errors.add(:source_file, "must be one of: #{SUPPORTED_FILE_EXTENSIONS.join(', ')}")
    end

    if source_file.byte_size > MAX_SOURCE_FILE_SIZE
      errors.add(:source_file, "must be smaller than 50MB")
    end
  end
end
