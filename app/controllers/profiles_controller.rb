class ProfilesController < ApplicationController
  def show
  end

  def update
    if Current.user.update(profile_params)
      redirect_to root_path, notice: "Senha alterada com sucesso."
    else
      render :show, status: :unprocessable_entity
    end
  end

  private

  def profile_params
    params.permit(:password, :password_confirmation)
  end
end
