class StudyChatsController < ApplicationController
  before_action :set_material
  before_action :limit_chat_messages!, only: :create

  def show
    @chat_session = find_or_create_session
    @messages = @chat_session.chat_messages.recent
  end

  def create
    @chat_session = find_or_create_session
    message = params[:message].to_s
    Study::StudyChatService.new(chat_session: @chat_session, user_message: message).call if message.present?
    redirect_to study_chat_material_path(@material)
  end

  private

  def set_material
    @material = current_user.materials.find(params[:id])
  end

  def find_or_create_session
    current_user.chat_sessions.find_or_create_by!(mode: "study", material: @material) do |session|
      session.title = "Study Chat: #{@material.title}"
    end
  end

  def limit_chat_messages!
    enforce_rate_limit!(bucket: "study_chat", limit: 30, window: 1.hour.to_i)
  end
end
