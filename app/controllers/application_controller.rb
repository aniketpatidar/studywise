class ApplicationController < ActionController::Base
  # Only allow modern browsers supporting webp images, web push, badges, import maps, CSS nesting, and CSS :has.
  allow_browser versions: :modern
  include Authentication
  include RateLimitable

  before_action :resume_session
  before_action :require_authentication
end
