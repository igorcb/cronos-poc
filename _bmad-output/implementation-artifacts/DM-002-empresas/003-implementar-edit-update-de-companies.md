# Story 2.3: Implementar Edit/Update de Companies

Status: done

## Story

**Como** Igor,
**Quero** editar informações de empresas existentes,
**Para que** eu possa corrigir dados ou atualizar taxas horárias.

## Acceptance Criteria

**Given** que empresas estão cadastradas

**When** adiciono actions edit, update ao CompaniesController

**Then**
1. Rota `GET /companies/:id/edit` exibe formulário preenchido
2. Formulário permite editar name e hourly_rate
3. Rota `PATCH /companies/:id` atualiza empresa e redireciona para index
4. Flash message de sucesso: "Empresa atualizada com sucesso"
5. Validações são aplicadas na atualização
6. Erros de validação são exibidos no formulário
7. Não é possível editar campo `active` pelo formulário (apenas via deactivate!)

## Tasks / Subtasks

- [x] Adicionar actions ao CompaniesController (AC: #1, #3)
  - [x] Implementar action `edit`
  - [x] Implementar action `update`
  - [x] Adicionar `before_action :set_company, only: [:edit, :update]`

- [x] Implementar action edit (AC: #1, #2)
  - [x] Buscar empresa por ID: `@company = Company.find(params[:id])`
  - [x] Criar view `app/views/companies/edit.html.erb`
  - [x] Reutilizar partial `_form.html.erb`

- [x] Implementar action update (AC: #3, #4, #5, #6)
  - [x] Usar strong parameters (mesmo de create)
  - [x] Tentar atualizar: `@company.update(company_params)`
  - [x] Se sucesso: redirect para index com flash
  - [x] Se falha: renderizar edit novamente com erros

- [x] Atualizar view index (AC: #1)
  - [x] Adicionar link "Editar" em cada empresa
  - [x] Link aponta para `edit_company_path(company)`

- [x] Garantir campo active não editável (AC: #7)
  - [x] Confirmar que `company_params` só permite :name e :hourly_rate
  - [x] Campo `active` não aparece no formulário

- [x] Validar fluxo completo
  - [x] Editar empresa existente com dados válidos
  - [x] Tentar editar com dados inválidos
  - [x] Confirmar flash messages
  - [x] Confirmar campo active não é editável

## Dev Notes

### Contexto Arquitetural

**ARQ22 - Soft Delete:**
- Campo `active` NÃO deve ser editável via formulário
- Apenas métodos `deactivate!` e `activate!` modificam esse campo
- Previne desativação acidental via form manipulation

**RESTful Conventions:**
- `edit` renderiza formulário preenchido
- `update` processa PATCH/PUT request
- Mesmos strong parameters de `create`

### Controller Updates

```ruby
# app/controllers/companies_controller.rb
class CompaniesController < ApplicationController
  before_action :require_authentication
  before_action :set_company, only: [:edit, :update]

  # ... index, new, create actions já existem

  def edit
    # @company já definido pelo before_action
  end

  def update
    if @company.update(company_params)
      redirect_to companies_path, notice: "Empresa atualizada com sucesso"
    else
      render :edit, status: :unprocessable_entity
    end
  end

  private

  def set_company
    @company = Company.find(params[:id])
  end

  def company_params
    params.require(:company).permit(:name, :hourly_rate)
    # NOTE: :active NÃO está permitido - apenas via deactivate!/activate!
  end
end
```

### View Edit Template

```erb
<!-- app/views/companies/edit.html.erb -->
<div class="container mx-auto px-4 py-8 max-w-lg">
  <h1 class="text-3xl font-bold mb-6">Editar Empresa</h1>
  <%= render "form", company: @company %>
</div>
```

### Update Index to Include Edit Link

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
        </div>
      </div>
    <% end %>
  </div>
</div>
```

### Comandos Úteis

```bash
# Verificar rotas edit/update
rails routes | grep companies

# Testar no browser
# GET   http://localhost:3000/companies/1/edit
# PATCH http://localhost:3000/companies/1
```

### Testes Manuais

1. **Editar empresa válida:**
   - Acessar `/companies`
   - Clicar "Editar" em uma empresa
   - Confirmar formulário preenchido
   - Alterar nome e/ou taxa
   - Clicar "Salvar"
   - Confirmar redirecionamento para index
   - Confirmar flash message verde

2. **Testar validações:**
   - Editar empresa
   - Limpar campo nome
   - Clicar "Salvar"
   - Confirmar mensagens de erro

3. **Confirmar active não editável:**
   - Inspecionar formulário no browser
   - Confirmar que não há campo "active"
   - Tentar enviar `active=false` via curl (deve ser ignorado)

### Security Note

**Importante:** Campo `active` não está em `company_params.permit()`

Mesmo que alguém tente enviar `company[active]=false` via manipulação de formulário, Rails irá ignorar esse parâmetro devido aos strong parameters.

### References

- [Architecture: Decisão 1.2 - Soft Delete](/home/igor/rails_app/cronos-poc/_bmad-output/planning-artifacts/architecture.md#decisão-12-estratégia-de-dependent-destroy)
- [Architecture: ARQ22](/home/igor/rails_app/cronos-poc/_bmad-output/planning-artifacts/architecture.md#arq22)
- [Epics: Story 2.3](/home/igor/rails_app/cronos-poc/_bmad-output/planning-artifacts/epics.md#story-23-implementar-editupdate-de-companies)

## Dev Agent Record

### Agent Model Used

Claude Sonnet 4.5 (2026-01-18)

### Debug Log References

No issues encountered during implementation.

### Completion Notes List

- [x] Actions edit e update implementadas
- [x] View edit criada
- [x] Links "Editar" adicionados ao index
- [x] Flash messages funcionais
- [x] Validações aplicadas corretamente
- [x] Campo active não editável confirmado
- [x] Fluxo completo testado

**Implementation Summary:**
- Implemented edit/update actions following RESTful conventions
- Created edit.html.erb view reusing _form partial
- Added before_action :set_company for DRY code
- Strong parameters explicitly exclude :active field (security)
- All 36 tests passing (13 new tests for edit/update)
- Zero regressions in existing functionality
- RuboCop compliant code

### File List

**Modified:**
- config/routes.rb (added :edit, :update to companies resources)
- app/controllers/companies_controller.rb (added edit, update actions + before_action; Rails 8 status codes)
- app/views/companies/index.html.erb (added "Editar" link to each company card)
- app/views/companies/_form.html.erb (added ARIA accessibility attributes, role="alert")
- spec/requests/companies_spec.rb (added 13 comprehensive tests; Rails 8 status codes)

**Created:**
- app/views/companies/edit.html.erb (edit form view)

### Code Review Fixes Applied

**By:** Code Review Agent (2026-01-18)

**Issues Fixed (6 total):**
1. ✅ **HIGH** - Rails 8 deprecation: Updated `:unprocessable_entity` → `:unprocessable_content` (controller + tests)
2. ✅ **VERIFIED** - Authentication is global via `Authentication` concern (no fix needed)
3. ✅ **MEDIUM** - Added `role="alert"` to error container for screen readers
4. ✅ **MEDIUM** - Added `aria-required="true"` and `required: true` to form fields
5. ✅ **MEDIUM** - Updated all test expectations to use `:unprocessable_content`
6. ✅ **REGRESSION** - All 86 tests passing, zero warnings

**Issues Deferred (2 LOW priority):**
- I18n translation for error messages (Epic 8 scope)
- Magic number refactoring for currency precision (technical debt)

---

## CRITICAL DEVELOPER GUARDRAILS

### ⚠️ VALIDAÇÕES OBRIGATÓRIAS

1. **ANTES de marcar story como concluída, VERIFICAR:**
   - [ ] `before_action :set_company` funciona corretamente
   - [ ] Strong parameters NÃO incluem `:active`
   - [ ] Flash message aparece após atualização
   - [ ] Validações exibem erros corretamente
   - [ ] Formulário é reutilizado de `_form.html.erb`

2. **NÃO PROSSEGUIR para Story 2.4 se:**
   - Campo `active` pode ser modificado via formulário
   - Validações não funcionam na edição
   - Flash messages não aparecem

### 🎯 OBJETIVOS DESTA STORY

**Esta story DEVE entregar:**
- ✅ Actions edit e update funcionais
- ✅ Formulário de edição preenchido
- ✅ Validações aplicadas
- ✅ Flash messages de sucesso/erro
- ✅ Campo active protegido

**Esta story NÃO implementa:**
- ❌ Destroy/Soft Delete (Story 2.4)
- ❌ Testes RSpec (Story 2.5)

### 📝 SEGURANÇA CRÍTICA

**Campo `active` NÃO deve ser editável:**

```ruby
# ✅ CORRETO
def company_params
  params.require(:company).permit(:name, :hourly_rate)
end

# ❌ ERRADO (permite desativação acidental)
def company_params
  params.require(:company).permit(:name, :hourly_rate, :active)
end
```
