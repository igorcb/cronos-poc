class ApplicationController < ActionController::Base
  include Authentication
  include TenantScoped
  # Only allow modern browsers supporting webp images, web push, badges, import maps, CSS nesting, and CSS :has.
  allow_browser versions: :modern

  # Tentativa de acessar recurso de outro tenant retorna 404 (não 403),
  # evitando vazar a existência do ID. Story 9.2 — DM-008 (AC5.3).
  rescue_from ActiveRecord::RecordNotFound, with: :render_not_found

  # Injeta dados customizados no payload lido pelo Lograge (custom_options em
  # production.rb). Story 11.1 — DM-010 (AC3.1). user_id vem da sessão atual
  # (Current.session&.user); nil quando não autenticado (AC2.1). Não incluímos
  # params/headers para não vazar senhas/tokens (AC2.2).
  def append_info_to_payload(payload)
    super
    payload[:user_id]    = Current.session&.user&.id
    payload[:request_id] = request.request_id
    payload[:ip]         = request.remote_ip
  end

  private

  def render_not_found
    # Story 9.2 QA #15: render plain em vez de file: para não depender de I/O em runtime.
    # Se public/404.html for removido por engano, o handler de erro não vira ele mesmo um erro.
    respond_to do |format|
      format.html         { render plain: "Not Found", status: :not_found }
      format.turbo_stream { head :not_found }
      format.json         { render json: { error: "not_found" }, status: :not_found }
      format.any          { head :not_found }
    end
  end
end
