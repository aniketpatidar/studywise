module RateLimitable
  extend ActiveSupport::Concern

  private

  def enforce_rate_limit!(bucket:, limit:, window:)
    user_id = current_user&.id || "anon"
    slot = (Time.current.to_i / window).to_i
    key = "rate:#{bucket}:u#{user_id}:#{slot}"

    count = Rails.cache.read(key).to_i
    if count >= limit
      redirect_back fallback_location: root_path, alert: "Rate limit reached. Please try again shortly."
      return false
    end

    Rails.cache.write(key, count + 1, expires_in: window + 5)
    true
  end
end
