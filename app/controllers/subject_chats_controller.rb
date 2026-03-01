class SubjectChatsController < ApplicationController
  SUBJECTS = %w[Math Physics Biology History].freeze
  before_action :limit_subject_chat_messages!, only: :create

  def index
    @subjects = SUBJECTS
    @sessions = current_user.chat_sessions.where(mode: "subject").recent
  end

  def show
    @chat_session = current_user.chat_sessions.find(params[:id])
    @messages = @chat_session.chat_messages.recent
  end

  def create
    subject_name = params[:subject_name].to_s.strip
    message = params[:message].to_s.strip
    chat_session = current_user.chat_sessions.find_or_create_by!(mode: "subject", subject_name:) do |session|
      session.title = "#{subject_name.titleize} Tutor"
    end
    Study::SubjectChatService.new(chat_session:, user_message: message).call if message.present?
    redirect_to subject_chat_path(chat_session)
  end

  private

  def limit_subject_chat_messages!
    enforce_rate_limit!(bucket: "subject_chat", limit: 30, window: 1.hour.to_i)
  end
end
