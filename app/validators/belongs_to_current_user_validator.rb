# Validador de integridade multi-tenant (story 9.2 — DM-008):
# Garante que uma referência (ex: company_id, project_id) aponta para um
# registro que pertence ao Current.user. Impede que User A crie uma Task
# referenciando a Company de User B mesmo conhecendo o ID.
#
# Uso:
#   validates :company_id, belongs_to_current_user: { class_name: "Company" }
#
# Comportamento:
# - Sem Current.user → no-op (factories e seeds podem criar livremente).
# - Valor nulo → no-op (presence validator já cobre obrigatoriedade).
# - Registro pertence ao Current.user → ok.
# - Registro pertence a outro user → adiciona erro :not_yours.
# - Registro inexistente → no-op (story 9.2 QA #20: separação de concerns):
#     * Em produção: FK constraint do Postgres rejeita no save.
#     * No model: belongs_to :company gera validator de presence que pega antes do save.
#   Este validator foca em "pertence ao tenant correto?", não em "existe?".
class BelongsToCurrentUserValidator < ActiveModel::EachValidator
  def validate_each(record, attribute, value)
    return unless Current.user
    return if value.blank?

    associated_class = options.fetch(:class_name).constantize
    return if associated_class.where(id: value, user_id: Current.user.id).exists?
    return unless associated_class.where(id: value).exists?

    record.errors.add(attribute, :not_yours, message: "não pertence ao usuário atual")
  end
end
