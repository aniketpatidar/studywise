class StudyChatsController < ApplicationController
  include ActionController::Live

  before_action :set_material
  before_action :ensure_material_chat_ready!, only: %i[create regenerate]
  before_action :limit_chat_messages!, only: %i[create stream regenerate]

  def show
    @chat_session = find_or_create_session
    @messages = @chat_session.chat_messages.recent
    @memory_mode = current_memory_mode
    @memory_mode_options = Study::StudyChatService.memory_mode_options
    @chat_enabled = material_chat_ready?
  end

  def create
    @chat_session = find_or_create_session
    message = params[:message].to_s.strip
    memory_mode = persist_memory_mode(params[:memory_mode])
    Study::StudyChatService.new(chat_session: @chat_session, user_message: message, memory_mode:).call if message.present?
    redirect_to study_chat_material_path(@material)
  end

  def stream
    unless material_chat_ready?
      render json: { error: chat_unavailable_message }, status: :unprocessable_entity
      return
    end

    @chat_session = find_or_create_session
    message = params[:message].to_s.strip
    memory_mode = persist_memory_mode(params[:memory_mode])

    if message.blank?
      render json: { error: "Message can't be blank." }, status: :unprocessable_entity
      return
    end

    response.headers["Content-Type"] = "text/event-stream"
    response.headers["Cache-Control"] = "no-cache"
    response.headers["X-Accel-Buffering"] = "no"

    response.stream.write(sse_event(type: "start"))

    Study::StudyChatService.new(
      chat_session: @chat_session,
      user_message: message,
      memory_mode:
    ).stream do |chunk|
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

  def regenerate
    @chat_session = find_or_create_session
    memory_mode = persist_memory_mode(params[:memory_mode])
    assistant_message = target_assistant_message
    if assistant_message.blank?
      redirect_to study_chat_material_path(@material), alert: "No AI response selected for retry."
      return
    end

    prompt_user = paired_user_message(assistant_message)
    if prompt_user.blank?
      redirect_to study_chat_material_path(@material), alert: "No user question found for this AI response."
      return
    end

    regenerated = Study::StudyChatService.new(
      chat_session: @chat_session,
      user_message: prompt_user.content,
      memory_mode:,
      persist_user_message: false,
      persist_assistant_message: false,
      excluded_message_ids: [assistant_message.id]
    ).call
    assistant_message.update!(content: regenerated)
    redirect_to study_chat_material_path(@material), notice: "Response retried."
  end

  def destroy
    @chat_session = find_or_create_session
    @chat_session.chat_messages.delete_all
    redirect_to study_chat_material_path(@material), notice: "Chat history cleared."
  end

  private

  def set_material
    @material = current_user.materials.friendly.find(params[:id])
  end

  def find_or_create_session
    current_user.chat_sessions.find_or_create_by!(mode: "study", material: @material) do |session|
      session.title = "Study Chat: #{@material.title}"
    end
  end

  def limit_chat_messages!
    return true unless material_chat_ready?
    return true if action_name == "create" && params[:message].to_s.strip.blank?

    enforce_rate_limit!(bucket: "study_chat", limit: 30, window: 1.hour.to_i)
  end

  def memory_mode_session_key
    "study_chat_memory_mode:m#{@material.id}"
  end

  def current_memory_mode
    Study::StudyChatService.normalize_memory_mode(session[memory_mode_session_key])
  end

  def persist_memory_mode(value)
    mode = Study::StudyChatService.normalize_memory_mode(value)
    session[memory_mode_session_key] = mode
    mode
  end

  def sse_event(payload)
    "data: #{payload.to_json}\n\n"
  end

  def material_chat_ready?
    @material.processed?
  end

  def chat_unavailable_message
    "Study chat unlocks after extraction completes. Generate notes first."
  end

  def ensure_material_chat_ready!
    return if material_chat_ready?

    redirect_to study_chat_material_path(@material), alert: chat_unavailable_message
  end

  def target_assistant_message
    if params[:assistant_message_id].present?
      @chat_session.chat_messages.find_by(id: params[:assistant_message_id], role: "assistant")
    else
      @chat_session.chat_messages.where(role: "assistant").order(created_at: :desc).first
    end
  end

  def paired_user_message(assistant_message)
    @chat_session.chat_messages
      .where(role: "user")
      .where("created_at <= ?", assistant_message.created_at)
      .order(created_at: :desc)
      .first
  end
end
