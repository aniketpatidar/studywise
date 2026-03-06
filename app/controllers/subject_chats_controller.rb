class SubjectChatsController < ApplicationController
  include ActionController::Live

  SUBJECTS = %w[Math Physics Biology History].freeze
  before_action :limit_subject_chat_messages!, only: %i[create stream]

  def index
    @subjects = SUBJECTS
    @sessions = current_user.chat_sessions.where(mode: "subject").recent
  end

  def show
    @chat_session = current_user.chat_sessions.where(mode: "subject").friendly.find(params[:id])
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

  def stream
    @chat_session = current_user.chat_sessions.where(mode: "subject").friendly.find(params[:id])
    message = params[:message].to_s.strip

    if message.blank?
      render json: { error: "Message can't be blank." }, status: :unprocessable_entity
      return
    end

    response.headers["Content-Type"] = "text/event-stream"
    response.headers["Cache-Control"] = "no-cache"
    response.headers["X-Accel-Buffering"] = "no"

    response.stream.write(sse_event(type: "start"))

    Study::SubjectChatService.new(chat_session: @chat_session, user_message: message).stream do |chunk|
      response.stream.write(sse_event(type: "chunk", content: chunk))
    end

    response.stream.write(sse_event(type: "done"))
  rescue ActionController::Live::ClientDisconnected
    nil
  rescue StandardError => e
    response.stream.write(sse_event(type: "error", message: e.message))
  ensure
    response.stream.close
  end

  private

  def limit_subject_chat_messages!
    return true if action_name == "create" && params[:message].to_s.strip.blank?
    return true if action_name == "stream" && params[:message].to_s.strip.blank?

    enforce_rate_limit!(bucket: "subject_chat", limit: 30, window: 1.hour.to_i)
  end

  def sse_event(payload)
    "data: #{payload.to_json}\n\n"
  end
end
