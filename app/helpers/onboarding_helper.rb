# View helper de onboarding (story 9.3 — DM-008).
#
# Apenas adapta o PORO `OnboardingState` para uso direto em ERB (e formata
# o nome do usuário). Não detém regras de negócio — toda lógica está no
# PORO, testável isoladamente.
module OnboardingHelper
  # Renderiza o primeiro nome para saudações. Fallback duplo (QA 9.3 #H5):
  # name.split.first → prefixo do email → "amigo".
  FALLBACK_FIRST_NAME = "amigo".freeze

  def display_first_name(user)
    return FALLBACK_FIRST_NAME if user.blank?

    user.name.to_s.split.first.presence ||
      user.email.to_s.split("@").first.presence ||
      FALLBACK_FIRST_NAME
  end

  # Mapeia um step do onboarding para o path do CTA correspondente.
  # Loud failure (QA #M1) para step desconhecido — espelha guard do PORO.
  def onboarding_step_path(step_key)
    case step_key
    when :step_1 then new_company_path
    when :step_2 then new_project_path
    when :step_3 then new_task_path
    else raise ArgumentError, "step desconhecido: #{step_key.inspect}"
    end
  end
end
