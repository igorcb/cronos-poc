# Story 3.2: Implementar CRUD de Projects (Index e New/Create)

Status: done

## Story

**Como** Igor,
**Quero** visualizar projetos e cadastrar novos projetos associados a empresas,
**Para que** eu possa organizar meu trabalho por projeto.

## Acceptance Criteria

**Given** que a tabela projects existe

**When** crio ProjectsController com actions index, new, create

**Then**
1. Rota `GET /projects` exibe lista de projetos
2. Lista mostra: nome do projeto, empresa associada, data de criação
3. Rota `GET /projects/new` exibe formulário de cadastro
4. Formulário possui: name (text), company_id (select dropdown)
5. Dropdown de empresas mostra apenas `Company.active`
6. Rota `POST /projects` cria projeto e redireciona para index
7. Flash message: "Projeto cadastrado com sucesso"
8. Validações aplicadas: name e company_id obrigatórios
9. Controller exige autenticação

## Tasks / Subtasks

- [x] Configurar rotas
  - [x] Adicionar `resources :projects` em routes.rb

- [x] Criar ProjectsController
  - [x] `rails generate controller Projects index new create`
  - [x] Adicionar `before_action :require_authentication`
  - [x] Implementar actions index, new, create

- [x] Criar views
  - [x] index.html.erb com lista de projetos
  - [x] new.html.erb com formulário
  - [x] _form.html.erb partial

- [x] Testar fluxo completo

## Dev Notes

### Controller Template

```ruby
# app/controllers/projects_controller.rb
class ProjectsController < ApplicationController
  before_action :require_authentication

  def index
    @projects = Project.includes(:company).order(created_at: :desc)
  end

  def new
    @project = Project.new
    @companies = Company.active.order(:name)
  end

  def create
    @project = Project.new(project_params)

    if @project.save
      redirect_to projects_path, notice: "Projeto cadastrado com sucesso"
    else
      @companies = Company.active.order(:name)
      render :new, status: :unprocessable_entity
    end
  end

  private

  def project_params
    params.require(:project).permit(:name, :company_id)
  end
end
```

### Form Partial

```erb
<!-- app/views/projects/_form.html.erb -->
<%= form_with(model: project, class: "space-y-4") do |form| %>
  <% if project.errors.any? %>
    <div class="bg-red-100 border border-red-400 text-red-700 px-4 py-3 rounded">
      <ul class="list-disc list-inside">
        <% project.errors.full_messages.each do |message| %>
          <li><%= message %></li>
        <% end %>
      </ul>
    </div>
  <% end %>

  <div>
    <%= form.label :name, "Nome do Projeto" %>
    <%= form.text_field :name, class: "mt-1 block w-full rounded-md border-gray-300" %>
  </div>

  <div>
    <%= form.label :company_id, "Empresa" %>
    <%= form.collection_select :company_id, @companies, :id, :name,
        { prompt: "Selecione uma empresa" },
        { class: "mt-1 block w-full rounded-md border-gray-300" } %>
  </div>

  <%= form.submit "Salvar", class: "bg-blue-600 text-white px-4 py-2 rounded" %>
<% end %>
```

## CRITICAL DEVELOPER GUARDRAILS

- [x] Dropdown mostra APENAS `Company.active`
- [x] Eager loading usado: `Project.includes(:company)`
- [x] Validações client-side e server-side

## Dev Agent Record

**Implementação Completa:**
- Rotas: resources :projects adicionado em [config/routes.rb:5](config/routes.rb#L5)
- Controller: [app/controllers/projects_controller.rb](app/controllers/projects_controller.rb)
  - before_action :require_authentication implementado
  - index com eager loading: Project.includes(:company)
  - new com Company.active.order(:name)
  - create com redirect e flash message
- Views implementadas:
  - [app/views/projects/index.html.erb](app/views/projects/index.html.erb) - Lista de projetos com card design
  - [app/views/projects/new.html.erb](app/views/projects/new.html.erb) - Formulário novo projeto
  - [app/views/projects/_form.html.erb](app/views/projects/_form.html.erb) - Partial com collection_select para empresas ativas
- Testes: [spec/requests/projects_spec.rb](spec/requests/projects_spec.rb)
  - 32 exemplos, 0 falhas (após code review fixes)
  - Cobertura: autenticação completa (index/new/create), index vazio/populado, new com/sem empresas ativas, create válido/inválido, teste de ordenação melhorado

**Decisões Técnicas:**
- Utilizou mesmo padrão visual de Companies (Tailwind dark theme)
- Eager loading para evitar N+1 queries
- Dropdown filtra apenas Company.active conforme AC
- Flash message: "Projeto cadastrado com sucesso"
- Validações client-side (required) e server-side (model validations)

**Arquivos Modificados:**
1. config/routes.rb - Adicionado resources :projects
2. app/controllers/projects_controller.rb - Controller completo (Rails 8 status code)
3. app/views/projects/index.html.erb - View index
4. app/views/projects/new.html.erb - View new
5. app/views/projects/_form.html.erb - Form partial com ARIA labels
6. app/models/project.rb - Validações explícitas
7. app/views/layouts/application.html.erb - Link navegação "Projetos"
8. spec/requests/projects_spec.rb - Testes completos (32 exemplos)

---

## Code Review Fixes Applied

**Review Date:** 2026-01-19
**Reviewer:** Code Review Agent (Adversarial)
**Issues Found:** 9 (3 High, 4 Medium, 2 Low)
**All Issues Fixed:** ✅

### HIGH Fixes Applied:
1. ✅ **Navigation Link** - Link "Projetos" adicionado ao menu desktop e mobile [app/views/layouts/application.html.erb:43,77](app/views/layouts/application.html.erb#L43)
2. ✅ **Model Validation** - `validates :company_id, presence: true` explícito [app/models/project.rb:22](app/models/project.rb#L22)
3. ✅ **Rails 8 Status** - `:unprocessable_entity` → `:unprocessable_content` [app/controllers/projects_controller.rb:20](app/controllers/projects_controller.rb#L20)

### MEDIUM Fixes Applied:
4. ✅ **Test: Empty Dropdown** - Contexto para dropdown sem empresas [spec/requests/projects_spec.rb:98-109](spec/requests/projects_spec.rb#L98-L109)
5. ✅ **Test: Auth Coverage** - Testes para new e create authentication [spec/requests/projects_spec.rb:17-25](spec/requests/projects_spec.rb#L17-L25)
6. ✅ **Test: Ordering** - Teste melhorado com timestamps e verificação de posição [spec/requests/projects_spec.rb:66-79](spec/requests/projects_spec.rb#L66-L79)

### LOW Fixes Applied:
7. ✅ **Accessibility** - `aria-labelledby` no dropdown [app/views/projects/_form.html.erb:30](app/views/projects/_form.html.erb#L30)
8. ✅ **Code Cleanup** - Helper vazio removido

**Final Test Results:** 32 examples, 0 failures ✅
