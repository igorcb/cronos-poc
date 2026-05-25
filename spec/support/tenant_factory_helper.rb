# Multi-tenant test helper (story 9.2 — DM-008 + QA #4, #18):
#
# Específico para specs de request. Após `sign_in(user)` (qualquer flavor),
# a cookie de sessão fica setada no test session. Hookamos no ciclo de
# request para extrair o user da Session correspondente e expor via
# `TenantFactoryHelper.current_test_user`. As factories `:company`/`:project`/
# `:task`/`:task_item` consultam essa thread-local como fallback ao
# atributo `user`, evitando ter que reescrever 100+ specs antigos.
#
# Specs novos que passam `user:` explicitamente continuam funcionando — a
# override do atributo prevalece sobre o default.
#
# Mudanças QA story 9.2:
# - #4: prepend antes só dentro de `before(:suite)` (não polui ambiente fora de RSpec).
# - #4: removido rescue StandardError genérico — bugs reais devem estourar.
# - #18: cleanup simétrico (before + after) para não vazar Thread.current entre testes.
module TenantFactoryHelper
  CURRENT_TEST_USER_THREAD_KEY = :tenant_factory_current_user

  def self.current_test_user=(user)
    Thread.current[CURRENT_TEST_USER_THREAD_KEY] = user
  end

  def self.current_test_user
    Thread.current[CURRENT_TEST_USER_THREAD_KEY]
  end

  def self.reset!
    Thread.current[CURRENT_TEST_USER_THREAD_KEY] = nil
  end

  # Tenta inferir user da cookie de sessão presente na integration session.
  # Chamado automaticamente após cada request via patch instalado em before(:suite).
  def self.sync_from_cookies(integration_session)
    cookie_jar = integration_session.cookies
    return unless cookie_jar.respond_to?(:signed)

    session_id = cookie_jar.signed[:session_id]
    return if session_id.blank?

    session_record = Session.find_by(id: session_id)
    self.current_test_user = session_record&.user
  end
end

module TenantFactoryHelperRequestPatch
  def process(*args, **kwargs)
    result = super
    TenantFactoryHelper.sync_from_cookies(self)
    result
  end
end

RSpec.configure do |config|
  # Instala o patch apenas quando a suite RSpec roda — não polui Rake/scripts.
  config.before(:suite) do
    ActionDispatch::Integration::Session.prepend(TenantFactoryHelperRequestPatch)
  end

  # Cleanup simétrico — before + after (QA #18) garante reset mesmo se um teste raise.
  config.before(:each) { TenantFactoryHelper.reset! }
  config.after(:each)  { TenantFactoryHelper.reset! }
end
