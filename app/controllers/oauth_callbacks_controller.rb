class OauthCallbacksController < ApplicationController
  allow_unauthenticated_access only: %i[google failure]
  before_action :redirect_if_authenticated, only: :google

  def google
    auth = request.env["omniauth.auth"]
    if auth.blank?
      redirect_to login_path, alert: "Google sign-in failed."
      return
    end

    provider = auth["provider"].to_s
    uid = auth["uid"].to_s
    email = auth.dig("info", "email").to_s.downcase.strip
    name = auth.dig("info", "name").to_s.strip
    name = email.split("@").first if name.blank? && email.present?

    if provider.blank? || uid.blank? || email.blank?
      redirect_to login_path, alert: "Google sign-in did not return required profile data."
      return
    end

    user = User.find_by(oauth_provider: provider, oauth_uid: uid)

    if user.nil?
      user = User.find_by(email: email)

      if user
        if user.oauth_provider.present? && (user.oauth_provider != provider || user.oauth_uid != uid)
          redirect_to login_path, alert: "This email is linked to a different OAuth account."
          return
        end

        user.update!(oauth_provider: provider, oauth_uid: uid)
      else
        generated_password = SecureRandom.base58(32)
        user = User.new(
          name: name.presence || "StudyWISE User",
          email: email,
          oauth_provider: provider,
          oauth_uid: uid,
          password: generated_password,
          password_confirmation: generated_password
        )

        unless user.save
          redirect_to signup_path, alert: user.errors.full_messages.to_sentence
          return
        end
      end
    end

    start_new_session_for(user)
    redirect_to after_authentication_url, notice: "Signed in with Google."
  rescue ActiveRecord::RecordInvalid => e
    redirect_to login_path, alert: e.record.errors.full_messages.to_sentence
  end

  def failure
    message = params[:message].to_s.humanize.presence || "request failed"
    redirect_to login_path, alert: "Google sign-in failed: #{message}."
  end

  private

  def redirect_if_authenticated
    redirect_to root_path if user_signed_in?
  end
end
