# Configuração OmniAuth — Google OAuth 2.0 (story 9.1 — DM-008)
#
# Em test, sempre registramos o provider porque OmniAuth.test_mode = true
# substitui as credenciais reais por mocks (sem isso, request specs caem em 404).
# Em outros ambientes, só registra quando AMBAS as ENVs estão presentes — o
# mesmo guard usado em ApplicationHelper.google_oauth_enabled? na view, para
# evitar botão visível levando a 404.
oauth_enabled = Rails.env.test? || (ENV["GOOGLE_CLIENT_ID"].present? && ENV["GOOGLE_CLIENT_SECRET"].present?)

if oauth_enabled
  Rails.application.config.middleware.use OmniAuth::Builder do
    provider :google_oauth2,
             ENV["GOOGLE_CLIENT_ID"] || "test-client-id",
             ENV["GOOGLE_CLIENT_SECRET"] || "test-client-secret",
             scope: "email,profile,openid",
             prompt: "select_account",
             access_type: "online"
  end
end

OmniAuth.config.logger = Rails.logger
OmniAuth.config.allowed_request_methods = [ :post ]
OmniAuth.config.silence_get_warning = true
