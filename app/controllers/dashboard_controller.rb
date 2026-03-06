class DashboardController < ApplicationController
  before_action :ensure_admin

  def index
    @materials = current_user.materials.recent.limit(5)
    @notes_count = Note.joins(:material).where(materials: { user_id: current_user.id }).count
    @materials_count = current_user.materials.count
    @llm_events = LlmEvent.where(user_id: current_user.id).recent.limit(10)
    @llm_calls_24h = LlmEvent.where(user_id: current_user.id).where("created_at >= ?", 24.hours.ago)
    @llm_calls_count = @llm_calls_24h.count
    @llm_success_count = @llm_calls_24h.where(success: true).count
    @llm_failure_count = @llm_calls_count - @llm_success_count
    @llm_success_rate = if @llm_calls_count.positive?
      ((@llm_success_count.to_f / @llm_calls_count) * 100).round(1)
    else
      0.0
    end
    @llm_failure_rate = if @llm_calls_count.positive?
      ((@llm_failure_count.to_f / @llm_calls_count) * 100).round(1)
    else
      0.0
    end

    latencies = @llm_calls_24h.where.not(latency_ms: nil).pluck(:latency_ms).sort
    @llm_avg_latency = latencies.any? ? (latencies.sum.to_f / latencies.length).round(1) : 0.0
    @llm_p95_latency = if latencies.any?
      latencies[((latencies.length * 0.95).ceil - 1).clamp(0, latencies.length - 1)]
    else
      0
    end

    @llm_prompt_chars = @llm_calls_24h.sum(:prompt_chars)
    @llm_response_chars = @llm_calls_24h.sum(:response_chars)
    @llm_last_failure = @llm_calls_24h.where(success: false).recent.first

    @llm_operation_health = @llm_calls_24h.group(:operation).pluck(
      :operation,
      Arel.sql("COUNT(*)"),
      Arel.sql("SUM(CASE WHEN success THEN 1 ELSE 0 END)"),
      Arel.sql("AVG(latency_ms)")
    ).map do |operation, total, success_total, avg_latency|
      success_rate = total.to_i.positive? ? ((success_total.to_f / total.to_i) * 100).round(1) : 0.0
      {
        operation: operation,
        total: total.to_i,
        success_rate: success_rate,
        avg_latency: avg_latency.to_f.round(1)
      }
    end.sort_by { |row| -row[:total] }

    @llm_health_label, @llm_health_style = if @llm_calls_count.zero?
      ["No data", "bg-slate-50 text-slate-700 border-slate-200"]
    elsif @llm_success_rate >= 98.0 && @llm_p95_latency <= 6_000
      ["Healthy", "bg-emerald-50 text-emerald-700 border-emerald-100"]
    elsif @llm_success_rate >= 90.0
      ["Degraded", "bg-amber-50 text-amber-700 border-amber-100"]
    else
      ["Unstable", "bg-rose-50 text-rose-700 border-rose-100"]
    end
  end

  private

  def ensure_admin
    redirect_to materials_path, alert: "Admin access required" unless current_user&.admin?
  end
end
