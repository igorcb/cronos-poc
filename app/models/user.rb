# == Schema Information
#
# Table name: users
#
#  id              :integer          not null, primary key
#  email           :string           not null
#  password_digest :string
#  created_at      :datetime         not null
#  updated_at      :datetime         not null
#  google_uid      :string
#  name            :string
#  avatar_url      :string
#
# Indexes
#
#  index_users_on_email       (email) UNIQUE
#  index_users_on_google_uid  (google_uid) UNIQUE
#

class User < ApplicationRecord
  # validations: false — permite usuários OAuth sem senha local.
  # Validações de senha são reaplicadas condicionalmente abaixo.
  has_secure_password validations: false
  has_many :sessions, dependent: :destroy

  generates_token_for :password_reset, expires_in: 15.minutes do
    password_salt&.last(10)
  end

  validates :email, presence: true, uniqueness: true
  validates :email, format: { with: URI::MailTo::EMAIL_REGEXP }
  validates :google_uid, uniqueness: true, allow_nil: true

  # Senha só é exigida/validada quando o usuário a está definindo.
  validates :password, length: { minimum: 8 }, if: -> { password.present? }
  validates :password, confirmation: true, if: -> { password.present? }
  validate :password_required_unless_oauth, on: :create

  normalizes :email, with: ->(e) { e.strip.downcase }

  def password_reset_token
    generate_token_for(:password_reset)
  end

  def password_reset_token_expires_in
    15.minutes.from_now
  end

  # Erro levantado quando o payload OAuth não traz dados mínimos (email/uid).
  class OauthInvalidPayloadError < StandardError; end

  # Cria ou atualiza um User a partir do hash de auth do OmniAuth Google.
  # Estratégia: busca por google_uid → fallback por email → cria novo.
  # Preserva password_digest do usuário existente (caso admin com senha).
  #
  # Guards (QA findings 9.1):
  # - #1 CRITICAL: payload sem email/uid sequestra user com email nil → raise explícito.
  # - #2 HIGH: race RecordNotUnique em callbacks paralelos → retry único após reload.
  # - #3 HIGH: email mudou no Google e bate com outro user → não sobrescrever email,
  #   apenas vincular google_uid/name/avatar no user atual (achado por google_uid).
  def self.from_google_omniauth(auth)
    incoming_email = auth&.info&.email
    incoming_uid   = auth&.uid

    if incoming_email.blank? || incoming_uid.blank?
      raise OauthInvalidPayloadError, "Google auth sem email ou uid"
    end

    attempts = 0
    begin
      user = find_by(google_uid: incoming_uid) || find_or_initialize_by(email: incoming_email)

      attributes = {
        google_uid: incoming_uid,
        name: auth.info.name,
        avatar_url: auth.info.image
      }
      # Só atualiza email se NÃO conflita com outro user existente.
      conflicting_email = user.persisted? &&
                          user.email != incoming_email &&
                          User.where(email: incoming_email).where.not(id: user.id).exists?
      attributes[:email] = incoming_email unless conflicting_email

      user.assign_attributes(attributes)
      user.save!
      user
    rescue ActiveRecord::RecordNotUnique
      attempts += 1
      retry if attempts <= 1
      raise
    end
  end

  private

  def password_required_unless_oauth
    return if google_uid.present?
    return if password_digest.present?

    errors.add(:password, :blank) if password.blank?
  end
end
