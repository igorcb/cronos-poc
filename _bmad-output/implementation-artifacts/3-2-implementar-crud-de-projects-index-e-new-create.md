# Story 3.2: Implementar CRUD de Projects (Index e New/Create)

Status: ready-for-dev

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

- [ ] Configurar rotas
  - [ ] Adicionar `resources :projects` em routes.rb

- [ ] Criar ProjectsController
  - [ ] `rails generate controller Projects index new create`
  - [ ] Adicionar `before_action :require_authentication`
  - [ ] Implementar actions index, new, create

- [ ] Criar views
  - [ ] index.html.erb com lista de projetos
  - [ ] new.html.erb com formulário
  - [ ] _form.html.erb partial

- [ ] Testar fluxo completo

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

- [ ] Dropdown mostra APENAS `Company.active`
- [ ] Eager loading usado: `Project.includes(:company)`
- [ ] Validações client-side e server-side
