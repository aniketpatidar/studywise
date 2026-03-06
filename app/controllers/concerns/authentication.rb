module Authentication
  extend ActiveSupport::Concern

  included do
    helper_method :current_user, :user_signed_in?
  end

  class_methods do
    def allow_unauthenticated_access(**options)
      skip_before_action :require_authentication, **options
    end
  end

  private

  def require_authentication
    resume_session
    return if Current.user

    session[:return_to_after_authenticating] = request.url
    redirect_to login_path
  end

  def current_user
    Current.user
  end

  def user_signed_in?
    current_user.present?
  end

  def resume_session
    Current.user ||= User.find_by(id: session[:user_id]) if session[:user_id]
  end

  def start_new_session_for(user)
    reset_session
    session[:user_id] = user.id
    Current.user = user
  end

  def terminate_session
    reset_session
    Current.user = nil
  end

  def after_authentication_url
    session.delete(:return_to_after_authenticating) || materials_path
  end
end
