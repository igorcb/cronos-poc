class BackfillUserIdInTenantTables < ActiveRecord::Migration[8.0]
  disable_ddl_transaction!

  # Backfill multi-tenant (story 9.2 — DM-008):
  # Estratégia de seleção do user inicial:
  #   1. ENV["INITIAL_TENANT_EMAIL"] (preferencial — explícito no deploy)
  #   2. Primeiro user com google_uid (presumido "tenant principal")
  #   3. Primeiro user qualquer (fallback dev/test)
  #   4. Tabela tenant vazia → no-op (DB fresco — não há o que migrar)
  #
  # Sem nenhum user E com dados a migrar → raise: impede inconsistência de FK.
  #
  # NOTE (QA #7): say_with_time + logs explícitos para debug post-mortem em prod.
  # Esta migration já rodou em dev/test deste projeto — as melhorias abaixo só têm
  # efeito em deploys futuros (outras instâncias, prod, restore de backup).
  def up
    if no_tenant_rows_to_backfill?
      say "Nenhuma row sem user_id em companies/projects/tasks/task_items — nada a backfillar."
      return
    end

    initial_user = find_initial_tenant_user
    if initial_user.nil?
      raise <<~MSG
        Backfill de multi-tenancy abortado: existe ao menos uma row em companies/projects/tasks/task_items
        sem user_id, mas nenhum User foi encontrado para atribuição.
        Defina ENV["INITIAL_TENANT_EMAIL"] apontando para um user existente antes de rodar a migration.
      MSG
    end

    log_backfill_plan(initial_user)

    say_with_time "Backfill: atribuindo user_id=#{initial_user.id} (#{initial_user.email}) em 4 tabelas" do
      User.transaction do
        %w[companies projects tasks task_items].each do |table|
          updated = execute("UPDATE #{table} SET user_id = #{initial_user.id} WHERE user_id IS NULL").cmd_tuples
          say "  → #{table}: #{updated} row(s) atualizadas", true
        end
      end
    end
  end

  def down
    # No-op: removendo user_id na migration de enforce também desfaz indiretamente.
    # Restaurar associações originais não é possível sem snapshot anterior.
  end

  private

  def no_tenant_rows_to_backfill?
    %w[companies projects tasks task_items].none? do |table|
      ActiveRecord::Base.connection.select_value("SELECT 1 FROM #{table} WHERE user_id IS NULL LIMIT 1")
    end
  end

  def find_initial_tenant_user
    email = ENV["INITIAL_TENANT_EMAIL"]
    if email.present?
      user = User.find_by(email: email.strip.downcase)
      say "  ✓ INITIAL_TENANT_EMAIL='#{email}' → User##{user.id}" if user
      return user if user

      say "  ⚠ INITIAL_TENANT_EMAIL='#{email}' não encontrou nenhum User — caindo no fallback."
    end

    by_oauth = User.where.not(google_uid: nil).order(:created_at).first
    if by_oauth
      say "  ✓ Fallback: primeiro user com google_uid → User##{by_oauth.id} (#{by_oauth.email})"
      return by_oauth
    end

    by_oldest = User.order(:created_at).first
    if by_oldest
      say "  ⚠ Fallback: primeiro user qualquer → User##{by_oldest.id} (#{by_oldest.email}) — VERIFIQUE se é o tenant correto!"
      return by_oldest
    end

    nil
  end

  def log_backfill_plan(initial_user)
    say "Backfill plan:"
    say "  Target user: ##{initial_user.id} <#{initial_user.email}>"
    %w[companies projects tasks task_items].each do |table|
      count = ActiveRecord::Base.connection.select_value("SELECT COUNT(*) FROM #{table} WHERE user_id IS NULL")
      say "  #{table}: #{count} row(s) a backfillar"
    end
  end
end
