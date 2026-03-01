class DashboardController < ApplicationController
  def index
    @materials = current_user.materials.recent.limit(5)
    @notes_count = Note.joins(:material).where(materials: { user_id: current_user.id }).count
    @materials_count = current_user.materials.count
    @llm_events = LlmEvent.where(user_id: current_user.id).recent.limit(10)
    @llm_calls_24h = LlmEvent.where(user_id: current_user.id).where("created_at >= ?", 24.hours.ago)
    @llm_success_rate = if @llm_calls_24h.any?
      ((@llm_calls_24h.where(success: true).count.to_f / @llm_calls_24h.count) * 100).round(1)
    else
      0.0
    end
    @llm_avg_latency = @llm_calls_24h.where.not(latency_ms: nil).average(:latency_ms)&.to_f&.round(1) || 0.0
    @llm_prompt_chars = @llm_calls_24h.sum(:prompt_chars)
    @llm_response_chars = @llm_calls_24h.sum(:response_chars)
  end
end
