# Story 2.4: Implementar Soft Delete de Companies

Status: ready-for-dev

## Story

**Como** Igor,
**Quero** desativar empresas ao invés de deletá-las,
**Para que** dados históricos sejam preservados.

## Acceptance Criteria

**Given** que empresas estão cadastradas

**When** adiciono action destroy ao CompaniesController

**Then**
1. Rota `DELETE /companies/:id` chama `company.deactivate!`
2. Empresa tem campo `active` atualizado para `false`
3. Empresa desativada não aparece mais em `Company.active`
4. Empresa desativada não aparece na lista index
5. Flash message: "Empresa desativada com sucesso"
6. Tentativa de `destroy` hard delete é bloqueada se houver time_entries associadas
7. Link "Desativar" aparece na lista de empresas

## Tasks / Subtasks

- [ ] Adicionar action destroy ao CompaniesController (AC: #1, #2, #5)
  - [ ] Implementar action `destroy`
  - [ ] Chamar `@company.deactivate!` ao invés de `destroy`
  - [ ] Redirect para index com flash de sucesso
  - [ ] Adicionar `before_action :set_company, only: [:edit, :update, :destroy]`

- [ ] Atualizar view index (AC: #7)
  - [ ] Adicionar link/botão "Desativar" em cada empresa
  - [ ] Usar `button_to` com `method: :delete`
  - [ ] Adicionar confirmação: `data: { turbo_confirm: "Tem certeza?" }`

- [ ] Validar comportamento de soft delete (AC: #2, #3, #4)
  - [ ] Desativar empresa
  - [ ] Confirmar `active` mudou para `false`
  - [ ] Confirmar empresa não aparece em `Company.active`
  - [ ] Confirmar empresa não aparece no index

- [ ] Validar proteção contra hard delete (AC: #6)
  - [ ] Model Company já possui override de `destroy` (Story 2.1)
  - [ ] Se houver time_entries, erro é lançado
  - [ ] Soft delete via `deactivate!` sempre funciona

- [ ] Estilizar botão de desativar
  - [ ] Cor vermelha para indicar ação destrutiva
  - [ ] Confirmação via Turbo

- [ ] Testar fluxo completo
  - [ ] Desativar empresa sem time_entries
  - [ ] Confirmar flash message
  - [ ] Confirmar empresa sumiu da lista

## Dev Notes

### Contexto Arquitetural

**ARQ22 - Soft Delete:**
- Companies nunca são deletadas permanentemente
- Método `deactivate!` muda `active` para `false`
- Histórico de time_entries preservado intacto

**Turbo Confirm:**
- `data: { turbo_confirm: "mensagem" }` exibe confirmação antes de enviar request
- Nativo do Turbo, não precisa JavaScript customizado

### Controller Updates

```ruby
# app/controllers/companies_controller.rb
class CompaniesController < ApplicationController
  before_action :require_authentication
  before_action :set_company, only: [:edit, :update, :destroy]

  # ... index, new, create, edit, update já existem

  def destroy
    @company.deactivate!
    redirect_to companies_path, notice: "Empresa desativada com sucesso"
  rescue StandardError => e
    redirect_to companies_path, alert: "Erro ao desativar empresa: #{e.message}"
  end

  private

  def set_company
    @company = Company.find(params[:id])
  end

  def company_params
    params.require(:company).permit(:name, :hourly_rate)
  end
end
```

### Update Index View

```erb
<!-- app/views/companies/index.html.erb -->
<div class="container mx-auto px-4 py-8">
  <div class="flex justify-between items-center mb-6">
    <h1 class="text-3xl font-bold">Empresas</h1>
    <%= link_to "Nova Empresa", new_company_path, class: "bg-blue-600 text-white px-4 py-2 rounded hover:bg-blue-700" %>
  </div>

  <div class="grid gap-4 md:grid-cols-2 lg:grid-cols-3">
    <% @companies.each do |company| %>
      <div class="bg-white p-4 rounded-lg shadow">
        <h3 class="text-lg font-semibold"><%= company.name %></h3>
        <p class="text-gray-600">R$ <%= number_to_currency(company.hourly_rate, unit: '') %>/hora</p>
        <p class="text-sm text-gray-500 mt-2">Criado em <%= l(company.created_at, format: :short) %></p>

        <div class="mt-4 flex gap-2">
          <%= link_to "Editar", edit_company_path(company), class: "text-blue-600 hover:underline text-sm" %>
          <%= button_to "Desativar", company_path(company), method: :delete,
                        class: "text-red-600 hover:underline text-sm",
                        data: { turbo_confirm: "Tem certeza que deseja desativar esta empresa?" } %>
        </div>
      </div>
    <% end %>
  </div>

  <% if @companies.empty? %>
    <p class="text-gray-500 text-center mt-8">Nenhuma empresa cadastrada.</p>
  <% end %>
</div>
```

### Model Review (já implementado na Story 2.1)

```ruby
# app/models/company.rb
class Company < ApplicationRecord
  # ...

  def deactivate!
    update!(active: false)
  end

  def activate!
    update!(active: true)
  end

  # Override destroy para prevenir deleção acidental
  def destroy
    if time_entries.exists?
      errors.add(:base, "Não é possível deletar empresa com entradas de tempo associadas. Use deactivate! para desativar.")
      throw(:abort)
    else
      super
    end
  end
end
```

### Comandos Úteis

```bash
# Verificar rota destroy
rails routes | grep companies | grep DELETE

# Testar no console
company = Company.first
company.deactivate!
company.active  # => false

Company.active  # => não inclui empresa desativada
```

### Testes Manuais

1. **Desativar empresa sem time_entries:**
   - Acessar `/companies`
   - Clicar "Desativar" em uma empresa
   - Confirmar dialog "Tem certeza?"
   - Confirmar redirecionamento para index
   - Confirmar flash message verde
   - Confirmar empresa sumiu da lista

2. **Verificar no console:**
   ```ruby
   company = Company.last
   company.active  # => false

   Company.active.include?(company)  # => false
   Company.all.include?(company)  # => true (registro existe no DB)
   ```

3. **Reativar empresa (opcional, via console):**
   ```ruby
   company = Company.find(id)
   company.activate!
   company.active  # => true
   ```

### Future Enhancement (Opcional)

**Adicionar view de empresas inativas:**
- Criar rota `/companies/inactive`
- Listar empresas desativadas com botão "Reativar"
- Implementar action `reactivate` no controller

**NÃO implementar nesta story** - apenas soft delete básico.

### References

- [Architecture: Decisão 1.2 - Soft Delete](/home/igor/rails_app/cronos-poc/_bmad-output/planning-artifacts/architecture.md#decisão-12-estratégia-de-dependent-destroy)
- [Architecture: ARQ22](/home/igor/rails_app/cronos-poc/_bmad-output/planning-artifacts/architecture.md#arq22)
- [Epics: Story 2.4](/home/igor/rails_app/cronos-poc/_bmad-output/planning-artifacts/epics.md#story-24-implementar-soft-delete-de-companies)

## Dev Agent Record

### Agent Model Used

_A ser preenchido pelo Dev Agent durante execução_

### Debug Log References

_A ser preenchido pelo Dev Agent se houver problemas_

### Completion Notes List

_A ser preenchido pelo Dev Agent ao finalizar:_
- [ ] Action destroy implementada
- [ ] Soft delete funcionando corretamente
- [ ] Botão "Desativar" adicionado ao index
- [ ] Confirmação Turbo funcionando
- [ ] Flash messages funcionais
- [ ] Empresa desativada não aparece em Company.active
- [ ] Fluxo completo testado

### File List

_A ser preenchido pelo Dev Agent com arquivos criados/modificados_

---

## CRITICAL DEVELOPER GUARDRAILS

### ⚠️ VALIDAÇÕES OBRIGATÓRIAS

1. **ANTES de marcar story como concluída, VERIFICAR:**
   - [ ] Action destroy chama `@company.deactivate!`
   - [ ] NÃO chama `@company.destroy` (hard delete)
   - [ ] Confirmação Turbo aparece antes de desativar
   - [ ] Flash message aparece após desativar
   - [ ] Empresa desativada não aparece no index
   - [ ] Empresa desativada ainda existe no database (active: false)

2. **NÃO PROSSEGUIR para Story 2.5 se:**
   - Destroy faz hard delete ao invés de soft delete
   - Empresa desativada ainda aparece no index
   - Dados históricos são perdidos

### 🎯 OBJETIVOS DESTA STORY

**Esta story DEVE entregar:**
- ✅ Soft delete funcional via `deactivate!`
- ✅ Confirmação antes de desativar
- ✅ Flash messages
- ✅ Empresas desativadas não aparecem em Company.active
- ✅ Dados históricos preservados

**Esta story NÃO implementa:**
- ❌ Reativação de empresas (feature futura)
- ❌ View de empresas inativas (feature futura)
- ❌ Testes RSpec (Story 2.5)

### 📝 SOFT DELETE CRÍTICO

**NUNCA fazer hard delete:**

```ruby
# ✅ CORRETO (soft delete)
def destroy
  @company.deactivate!
  redirect_to companies_path, notice: "Empresa desativada com sucesso"
end

# ❌ ERRADO (hard delete - perde dados)
def destroy
  @company.destroy
  redirect_to companies_path, notice: "Empresa deletada"
end
```

**Dados NUNCA devem ser perdidos.**
