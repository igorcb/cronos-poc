# frozen_string_literal: true

# Falha o boot em produção se ENVs críticas estiverem ausentes.
# Prefixo 000_ garante execução antes de qualquer outro initializer que leia ENVs
# (ex: omniauth.rb lê GOOGLE_CLIENT_ID).
#
# Encapsulado em módulo para permitir teste isolado sem depender do boot real.
module ValidateEnvs
  CONFIG_PATH = Rails.root.join("config/required_envs.yml")

  module_function

  # Executa a validação para o ambiente informado.
  # Levanta RuntimeError listando TODAS as obrigatórias ausentes (não só a primeira).
  def call(env: Rails.env, config_path: CONFIG_PATH, logger: Rails.logger)
    return unless env.to_s == "production"
    # Pular durante build-time (assets:precompile no Docker). ENVs de runtime
    # não existem ainda; validação real acontece no boot do container.
    return if ENV["DISABLE_DATABASE"] == "1" || ENV["SECRET_KEY_BASE_DUMMY"] == "1"

    config = (YAML.safe_load_file(config_path) || {})[env.to_s] || {}

    missing_required = Array(config["required"]).reject { |k| ENV[k].present? }
    missing_optional = Array(config["optional"]).reject { |k| ENV[k].present? }

    if missing_required.any?
      raise <<~MSG
        Cronos POC não pode subir em produção sem as seguintes ENVs:
        #{missing_required.join(", ")}

        Configure no Railway dashboard (Variables) e re-deploy.
      MSG
    end

    missing_optional.each do |k|
      logger.warn("[boot] ENV opcional ausente: #{k}")
    end
  end
end

ValidateEnvs.call
