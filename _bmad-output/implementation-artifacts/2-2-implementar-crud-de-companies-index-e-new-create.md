# Story 2.2: Implementar CRUD de Companies (Index e New/Create)

Status: ready-for-dev

## Story

**Como** Igor,
**Quero** visualizar lista de empresas e cadastrar novas empresas,
**Para que** eu possa gerenciar as empresas que trabalho.

## Acceptance Criteria

**Given** que a tabela companies existe

**When** crio CompaniesController com actions index, new, create

**Then**
1. Rota `GET /companies` exibe lista de empresas ativas
2. Lista mostra: nome, taxa R$/hora, data de criação
3. Rota `GET /companies/new` exibe formulário de cadastro
4. Formulário possui campos: name (text), hourly_rate (number)
5. Rota `POST /companies` cria nova empresa e redireciona para index
6. Flash message de sucesso é exibida: "Empresa cadastrada com sucesso"
7. Validações são aplicadas: name e hourly_rate obrigatórios
8. Erro de validação exibe mensagens claras no formulário
9. Controller exige autenticação (`before_action :require_authentication`)

## Tasks / Subtasks

- [ ] Configurar rotas (AC: #1, #3, #5)
  - [ ] Adicionar `resources :companies` em `config/routes.rb`
  - [ ] Verificar rotas: `rails routes | grep companies`

- [ ] Criar CompaniesController (AC: #9)
  - [ ] `rails generate controller Companies index new create`
  - [ ] Adicionar `before_action :require_authentication` no controller
  - [ ] Implementar action `index`
  - [ ] Implementar action `new`
  - [ ] Implementar action `create`

- [ ] Implementar action index (AC: #1, #2)
  - [ ] Buscar apenas empresas ativas: `@companies = Company.active.order(created_at: :desc)`
  - [ ] Criar view `app/views/companies/index.html.erb`
  - [ ] Exibir lista com: nome, taxa, data de criação
  - [ ] Adicionar link "Nova Empresa" para new_company_path

- [ ] Implementar action new (AC: #3, #4)
  - [ ] Instanciar `@company = Company.new`
  - [ ] Criar view `app/views/companies/new.html.erb`
  - [ ] Criar partial `_form.html.erb` com campos name e hourly_rate
  - [ ] Usar `form_with model: @company`

- [ ] Implementar action create (AC: #5, #6, #7, #8)
  - [ ] Usar strong parameters: `company_params`
  - [ ] Tentar salvar: `@company.save`
  - [ ] Se sucesso: redirect para index com flash de sucesso
  - [ ] Se falha: renderizar new novamente com erros

- [ ] Estilizar views com Tailwind (AC: #2, #4, #8)
  - [ ] Lista de empresas responsiva
  - [ ] Formulário mobile-friendly
  - [ ] Exibir mensagens de erro claramente
  - [ ] Flash messages estilizadas

- [ ] Validar fluxo completo
  - [ ] Testar criação de empresa válida
  - [ ] Testar validações: enviar formulário vazio
  - [ ] Confirmar flash messages aparecem
  - [ ] Confirmar redirecionamento funciona

## Dev Notes

### Contexto Arquitetural

**ARQ39 - ViewComponent para UI reutilizável:**
- Por enquanto usar partials simples
- ViewComponents podem ser adicionados depois para cards/badges

**NFR7-NFR9 - Mobile-First:**
- Formulários devem ser responsivos (Tailwind breakpoints)
- Botões touch-friendly (min-height: 44px)

**ARQ28-ARQ33 - Autenticação:**
- Todos os controllers exigem autenticação
- Single-user: `before_action :require_authentication`

### Controller Template

```ruby
# app/controllers/companies_controller.rb
class CompaniesController < ApplicationController
  before_action :require_authentication

  def index
    @companies = Company.active.order(created_at: :desc)
  end

  def new
    @company = Company.new
  end

  def create
    @company = Company.new(company_params)

    if @company.save
      redirect_to companies_path, notice: "Empresa cadastrada com sucesso"
    else
      render :new, status: :unprocessable_entity
    end
  end

  private

  def company_params
    params.require(:company).permit(:name, :hourly_rate)
  end
end
```

### Routes

```ruby
# config/routes.rb
Rails.application.routes.draw do
  resources :companies
  # ... outras rotas
end
```

### View Index Template

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
      </div>
    <% end %>
  </div>
</div>
```

### Form Partial Template

```erb
<!-- app/views/companies/_form.html.erb -->
<%= form_with(model: company, class: "space-y-4") do |form| %>
  <% if company.errors.any? %>
    <div class="bg-red-100 border border-red-400 text-red-700 px-4 py-3 rounded">
      <h2 class="font-bold"><%= pluralize(company.errors.count, "erro") %> encontrado:</h2>
      <ul class="list-disc list-inside">
        <% company.errors.full_messages.each do |message| %>
          <li><%= message %></li>
        <% end %>
      </ul>
    </div>
  <% end %>

  <div>
    <%= form.label :name, "Nome", class: "block text-sm font-medium text-gray-700" %>
    <%= form.text_field :name, class: "mt-1 block w-full rounded-md border-gray-300 shadow-sm" %>
  </div>

  <div>
    <%= form.label :hourly_rate, "Taxa R$/hora", class: "block text-sm font-medium text-gray-700" %>
    <%= form.number_field :hourly_rate, step: 0.01, class: "mt-1 block w-full rounded-md border-gray-300 shadow-sm" %>
  </div>

  <div class="flex gap-2">
    <%= form.submit "Salvar", class: "bg-blue-600 text-white px-4 py-2 rounded hover:bg-blue-700" %>
    <%= link_to "Cancelar", companies_path, class: "bg-gray-300 text-gray-700 px-4 py-2 rounded hover:bg-gray-400" %>
  </div>
<% end %>
```

### View New Template

```erb
<!-- app/views/companies/new.html.erb -->
<div class="container mx-auto px-4 py-8 max-w-lg">
  <h1 class="text-3xl font-bold mb-6">Nova Empresa</h1>
  <%= render "form", company: @company %>
</div>
```

### Flash Messages Layout

```erb
<!-- app/views/layouts/application.html.erb -->
<!-- Adicionar antes de <%= yield %> -->
<% if notice %>
  <div class="bg-green-100 border border-green-400 text-green-700 px-4 py-3 rounded mb-4">
    <%= notice %>
  </div>
<% end %>

<% if alert %>
  <div class="bg-red-100 border border-red-400 text-red-700 px-4 py-3 rounded mb-4">
    <%= alert %>
  </div>
<% end %>
```

### Comandos Úteis

```bash
# Gerar controller
rails generate controller Companies index new create

# Verificar rotas
rails routes | grep companies

# Testar no browser
# GET  http://localhost:3000/companies
# GET  http://localhost:3000/companies/new
```

### Testes Manuais

1. **Listar empresas:**
   - Acessar `/companies`
   - Confirmar lista vazia ou com empresas ativas

2. **Criar empresa válida:**
   - Clicar "Nova Empresa"
   - Preencher nome: "Empresa Teste"
   - Preencher taxa: 150.50
   - Clicar "Salvar"
   - Confirmar redirecionamento para index
   - Confirmar flash message verde

3. **Testar validações:**
   - Clicar "Nova Empresa"
   - Deixar campos vazios
   - Clicar "Salvar"
   - Confirmar mensagens de erro em vermelho

### References

- [Architecture: Categoria 2 - Autenticação](/home/igor/rails_app/cronos-poc/_bmad-output/planning-artifacts/architecture.md#categoria-2-autenticação--segurança)
- [Architecture: NFR7-NFR9 - Mobile-First](/home/igor/rails_app/cronos-poc/_bmad-output/planning-artifacts/architecture.md#responsividade)
- [Epics: Story 2.2](/home/igor/rails_app/cronos-poc/_bmad-output/planning-artifacts/epics.md#story-22-implementar-crud-de-companies-index-e-newcreate)

## Dev Agent Record

### Agent Model Used

_A ser preenchido pelo Dev Agent durante execução_

### Debug Log References

_A ser preenchido pelo Dev Agent se houver problemas_

### Completion Notes List

_A ser preenchido pelo Dev Agent ao finalizar:_
- [ ] Controller criado com autenticação
- [ ] Rotas configuradas
- [ ] View index listando empresas
- [ ] View new com formulário
- [ ] Partial _form criado
- [ ] Flash messages funcionais
- [ ] Validações exibindo erros
- [ ] Fluxo completo testado

### File List

_A ser preenchido pelo Dev Agent com arquivos criados/modificados_

---

## CRITICAL DEVELOPER GUARDRAILS

### ⚠️ VALIDAÇÕES OBRIGATÓRIAS

1. **ANTES de marcar story como concluída, VERIFICAR:**
   - [ ] `before_action :require_authentication` presente no controller
   - [ ] Strong parameters implementados corretamente
   - [ ] Flash messages aparecem após criar empresa
   - [ ] Erros de validação são exibidos no formulário
   - [ ] Apenas empresas ativas aparecem no index
   - [ ] Formulário é responsivo em mobile

2. **NÃO PROSSEGUIR para Story 2.3 se:**
   - Controller não exige autenticação
   - Validações não estão funcionando
   - Flash messages não aparecem
   - Formulário não é mobile-friendly

### 🎯 OBJETIVOS DESTA STORY

**Esta story DEVE entregar:**
- ✅ Controller com index, new, create
- ✅ Views funcionais e responsivas
- ✅ Validações com mensagens de erro
- ✅ Flash messages de sucesso/erro
- ✅ Autenticação obrigatória

**Esta story NÃO implementa:**
- ❌ Edit/Update (Story 2.3)
- ❌ Destroy/Soft Delete (Story 2.4)
- ❌ Testes RSpec (Story 2.5)
- ❌ ViewComponents (incremento futuro)
