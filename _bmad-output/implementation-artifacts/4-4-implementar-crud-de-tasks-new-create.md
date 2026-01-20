# Story 4.4: Implementar CRUD de Tasks (New/Create)

Status: backlog

<!-- Note: Validation is optional. Run validate-create-story for quality check before dev-story. -->

## Story

**Como** Igor,
**Quero** criar novas tarefas rapidamente,
**Para que** eu possa organizar meu trabalho.

## Acceptance Criteria

**Given** que models e validações estão implementados

**When** crio TasksController com actions new, create

**Then**
1. rota `GET /tasks/new` exibe formulário
2. formulário possui: name (text), start_date (date picker), estimated_hours (number)
3. formulário possui: company_id (select), project_id (select), notes (textarea)
4. dropdown de companies mostra apenas `Company.active`
5. dropdown de projects é filtrado por company selecionada (Stimulus)
6. validação client-side confirma project pertence à company
7. rota `POST /tasks` cria task com status 'pending'
8. flash message: "Tarefa criada com sucesso"
9. validações tripla camada aplicam (migration, model, client-side)
10. tempo médio de criação < 45 segundos

## Tasks / Subtasks

- [ ] Criar TasksController
  - [ ] Criar arquivo `app/controllers/tasks_controller.rb`
  - [ ] Adicionar `before_action :require_authentication`
  - [ ] Adicionar action `new`
  - [ ] Adicionar action `create`
  - [ ] Instanciar Task novo em `new`
  - [ ] Usar strong params em `create`

- [ ] Implementar strong params
  - [ ] Definir método privado `task_params`
  - [ ] Permitir: :name, :company_id, :project_id, :start_date, :estimated_hours, :notes
  - [ ] Requerir: :name, :company_id, :project_id, :start_date, :estimated_hours

- [ ] Criar view new (formulário)
  - [ ] Criar arquivo `app/views/tasks/new.html.erb`
  - [ ] Adicionar campo `name` (text input)
  - [ ] Adicionar campo `start_date` (date picker, default: today)
  - [ ] Adicionar campo `estimated_hours` (number input, step: 0.01)
  - [ ] Adicionar dropdown `company_id` (select)
  - [ ] Adicionar dropdown `project_id` (select)
  - [ ] Adicionar campo `notes` (textarea)
  - [ ] Adicionar data atributo para Stimulus: `data-controller="project-selector"`
  - [ ] Adicionar botão submit

- [ ] Implementar lógica de filtro de projects por company
  - [ ] Criar Stimulus controller `project_selector_controller.js`
  - [ ] Adicionar action para carregar projects por company_id
  - [ ] Fazer fetch para `/projects.json?company_id=X`
  - [ ] Atualizar dropdown de projects com resultado
  - [ ] Limpar dropdown de projects quando company mudar

- [ ] Criar endpoint JSON para projects
  - [ ] Adicionar rota `get :projects, to: :projects_json, defaults: { format: :json }`
  - ] Implementar action `projects_json`
  - [ ] Filtrar projects por `company_id` params se presente
  - [ ] Retornar JSON com id e name de cada project

- [ ] Implementar action create
  - [ ] Criar `@task = Task.new(task_params)`
  - [ ] Definir `@task.status = 'pending'` (default)
  - [ ] Salvar com `@task.save`
  - [ ] Redirecionar para tasks_path ou root_path com flash
  - [ ] Tratar erros de validação renderizando :new

- [ ] Escrever testes
  - [ ] Testar acesso sem autenticação (deve falhar)
  - [ ] Testar criação de task válida
  - [ ] Testar validação de campos obrigatórios
  - [ ] Testar validação de consistência company/project
  - [ ] Testar filtro de projects por company
  - [ ] Testar redirecionamento após sucesso
  - [ ] Testar mensagens de flash
