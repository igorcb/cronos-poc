# Concern de multi-tenant scoping (story 9.2 — DM-008).
#
# Fornece helpers `scoped_*` que retornam a relation limitada ao Current.user.
# Substitui o uso direto de `Company`, `Project`, `Task`, `TaskItem` nos
# controllers para garantir isolamento de dados entre usuários.
#
# Princípio: o `current_user` é a única raiz autorizada — qualquer find/create
# parte dele. Tentativa de acessar recurso de outro user gera 404 (não 403),
# evitando vazar a existência de IDs.
#
# Contrato (story 9.2 QA #19): scoped_* exige `Current.user` setado.
# Endpoints públicos (passwords/registrations/omniauth) NÃO devem chamar scoped_*.
# Chamada sem Current.user levanta MissingTenantError — preferimos loud failure
# a vazar dados silenciosamente.
module TenantScoped
  extend ActiveSupport::Concern

  class MissingTenantError < StandardError; end

  private

  def scoped_companies
    require_current_user!
    Current.user.companies
  end

  def scoped_projects
    require_current_user!
    Current.user.projects
  end

  def scoped_tasks
    require_current_user!
    Current.user.tasks
  end

  def scoped_task_items
    require_current_user!
    Current.user.task_items
  end

  def scoped_idle_periods
    require_current_user!
    Current.user.idle_periods
  end

  def require_current_user!
    return if Current.user

    raise MissingTenantError,
          "TenantScoped helper called without Current.user. " \
          "Endpoint público ou bug: garanta autenticação antes de usar scoped_*."
  end
end
