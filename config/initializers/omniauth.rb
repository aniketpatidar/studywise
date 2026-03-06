OmniAuth.config.allowed_request_methods = %i[post]
OmniAuth.config.silence_get_warning = true

Rails.application.config.middleware.use OmniAuth::Builder do
  client_id = ENV["GOOGLE_OAUTH_CLIENT_ID"].to_s
  client_secret = ENV["GOOGLE_OAUTH_CLIENT_SECRET"].to_s

  if client_id.present? && client_secret.present?
    provider :google_oauth2,
      client_id,
      client_secret,
      scope: "email,profile",
      prompt: "select_account"
  else
    Rails.logger.warn("Google OAuth not configured: set GOOGLE_OAUTH_CLIENT_ID and GOOGLE_OAUTH_CLIENT_SECRET.")
  end
end
