# Onboarding state machine derivada dos counts do user (story 9.3 — DM-008).
#
# PORO consumido tanto por controllers quanto por views — não depende de
# ActionView, então pode ser testado isoladamente e instrumentado livremente.
#
# Steps:
#   :step_1    — 0 companies (passo Empresa)
#   :step_2    — 1+ companies, 0 projects (passo Projeto)
#   :step_3    — 1+ projects, 0 tasks (passo Tarefa)
#   :completed — 1+ tasks
#
# QA 9.3 #C1 / #H3 — substitui chamadas `helpers.onboarding_active?(user)`
# espalhadas em controllers; cacheia o `step` na instância para garantir
# uma única bateria de queries EXISTS por request.
class OnboardingState
  STEPS = [ :step_1, :step_2, :step_3, :completed ].freeze
  private_constant :STEPS

  def initialize(user)
    @user = user
  end

  def step
    @step ||= compute_step
  end

  def active?
    step != :completed
  end

  # Estado visual de cada passo dado o passo atual.
  #   :pending — passo atual (destacado / call-to-action)
  #   :locked  — passo futuro (cinza, sem CTA)
  #   :done    — passo já concluído (check verde)
  #
  # QA 9.3 #M2 — quando `step == :completed`, qualquer passo é :done (tela
  # de revisão pós-onboarding, se algum dia for renderizada).
  # QA 9.3 #M1 — step desconhecido levanta ArgumentError (loud failure).
  def step_state(target_step)
    validate_step!(target_step)
    return :done if step == :completed
    return :done if step_index(target_step) < step_index(step)
    return :pending if target_step == step
    :locked
  end

  private

  def compute_step
    return :completed if @user.tasks.exists?
    return :step_3    if @user.projects.exists?
    return :step_2    if @user.companies.exists?
    :step_1
  end

  def validate_step!(target_step)
    return if STEPS.include?(target_step)

    raise ArgumentError, "step desconhecido: #{target_step.inspect}"
  end

  def step_index(target_step)
    STEPS.index(target_step)
  end
end
