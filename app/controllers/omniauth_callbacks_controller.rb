class OmniauthCallbacksController < ApplicationController
  allow_unauthenticated_access only: %i[ google_oauth2 failure ]

  def google_oauth2
    user = User.from_google_omniauth(request.env["omniauth.auth"])
    start_new_session_for(user)
    redirect_to after_authentication_url, notice: "Bem-vindo, #{user.name.presence || user.email}!"
  rescue User::OauthInvalidPayloadError => e
    Rails.logger.warn("OAuth Google: payload inválido — #{e.message}")
    redirect_to new_session_path, alert: "Dados do Google incompletos. Tente novamente."
  rescue ActiveRecord::RecordInvalid => e
    Rails.logger.warn("OAuth Google: validação falhou — #{e.record.errors.full_messages.join(', ')}")
    redirect_to new_session_path, alert: "Não foi possível vincular sua conta Google."
  rescue ActiveRecord::RecordNotUnique => e
    Rails.logger.error("OAuth Google: conflito de unicidade — #{e.message}")
    redirect_to new_session_path, alert: "Conta já vinculada. Tente novamente."
  end

  def failure
    Rails.logger.warn("OAuth failure: #{params[:message]}")
    redirect_to new_session_path, alert: "Falha ao autenticar com Google."
  end
end
