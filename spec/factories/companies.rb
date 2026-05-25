# == Schema Information
#
# Table name: companies
#
#  id          :integer          not null, primary key
#  name        :string           not null
#  hourly_rate :decimal(10, 2)   not null
#  active      :boolean          default(TRUE), not null
#  created_at  :datetime         not null
#  updated_at  :datetime         not null
#  user_id     :integer          not null
#
# Indexes
#
#  index_companies_on_active              (active)
#  index_companies_on_user_id             (user_id)
#  index_companies_on_user_id_and_active  (user_id,active)
#

FactoryBot.define do
  factory :company do
    sequence(:name) { |n| "Company #{n}" }
    hourly_rate { 100.00 }
    active { true }
    # Multi-tenant (story 9.2 — DM-008): herança transparente em specs antigos.
    # Ordem de fallback:
    #   1) Caller passou `user:` explicitamente — sobrescreve o default.
    #   2) Helper de tenant já tem um user setado (post-sign_in via integration hook).
    #   3) Existe pelo menos um User no DB com Session ativa — reaproveita
    #      (controller specs setam cookies.signed[:session_id] mas não tocam Current).
    #   4) Existe exatamente UM User no DB (caso comum: `let!(:user)` no spec).
    #   5) Caso contrário, cria um User novo.
    user do
      # Ordem de preferência:
      #   1) Helper de tenant tem user setado (post-sign_in real via integration patch).
      #   2) Session ativa no DB — controller specs setam cookies.signed[:session_id].
      #   3) Existe pelo menos 1 User no DB — pega o último criado (let!(:user) padrão).
      #   4) Cria User novo.
      TenantFactoryHelper.current_test_user ||
        Session.order(:created_at).last&.user ||
        User.order(:created_at).last ||
        association(:user)
    end

    trait :inactive do
      active { false }
    end

    trait :high_rate do
      hourly_rate { 500.00 }
    end

    trait :low_rate do
      hourly_rate { 50.00 }
    end
  end
end
