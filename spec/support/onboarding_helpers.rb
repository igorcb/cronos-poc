# Spec helper para sair do gate de onboarding (story 9.3 — DM-008 QA #H4).
#
# Specs que usam dashboard root_path mas não estão exercitando onboarding
# precisam que o user tenha 1+ Company, 1+ Project e 1+ Task (state :completed).
# Centralizar em um único helper evita drift se a regra de "completed" mudar.
module OnboardingHelpers
  # Cria Company + Project + Task pertencentes ao user, fora do mês corrente
  # (para não interferir em filtros de dashboard "deste mês").
  def complete_onboarding_for(user, start_date: Date.current.beginning_of_month - 2.months)
    company = create(:company, user: user)
    project = create(:project, company: company, user: user)
    create(:task, company: company, project: project, user: user, start_date: start_date)
  end
end

RSpec.configure do |config|
  config.include OnboardingHelpers, type: :request
  config.include OnboardingHelpers, type: :controller
end
