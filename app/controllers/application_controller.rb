class ApplicationController < ActionController::Base
  # Only allow modern browsers supporting webp images, web push, badges, import maps, CSS nesting, and CSS :has.
  allow_browser versions: :modern
  include Pundit::Authorization
  include Authentication
  include RateLimitable

  helper_method :google_oauth_enabled?

  before_action :resume_session
  before_action :require_authentication

  rescue_from Pundit::NotAuthorizedError, with: :handle_not_authorized

  private

  def handle_not_authorized
    redirect_to admin_path, alert: "You are not allowed to access that page."
  end

  def google_oauth_enabled?
    ENV["GOOGLE_OAUTH_CLIENT_ID"].to_s.present? && ENV["GOOGLE_OAUTH_CLIENT_SECRET"].to_s.present?
  end
end
