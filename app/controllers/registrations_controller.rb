class RegistrationsController < ApplicationController
  allow_unauthenticated_access

  def new
    redirect_to new_session_path, alert: "Registro desabilitado. Sistema single-user."
  end

  def create
    redirect_to new_session_path, alert: "Registro desabilitado. Sistema single-user."
  end
end
