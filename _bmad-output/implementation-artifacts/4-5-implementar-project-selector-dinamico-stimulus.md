# Story 4.5: Implementar Project Selector Dinâmico com Stimulus

Status: backlog

<!-- Note: Validation is optional. Run validate-create-story for quality check before dev-story. -->

## Story

**Como** Igor,
**Quero** que projetos sejam filtrados pela empresa selecionada,
**Para que** eu não veja projetos de outras empresas.

## Acceptance Criteria

**Given** que formulário de Task existe

**When** crio `project_selector_controller.js` em Stimulus

**Then**
1. ao selecionar empresa no dropdown
2. dropdown de projetos atualiza via fetch para `/projects?company_id=X`
3. apenas projetos daquela empresa aparecem
4. se mudar empresa, lista de projetos atualiza novamente
5. endpoint `/projects.json?company_id=X` retorna JSON de projetos
6. interação é instantânea (< 300ms)

## Tasks / Subtasks

- [ ] Criar Stimulus controller `project_selector_controller.js`
  - [ ] Criar arquivo `app/javascript/controllers/project_selector_controller.js`
  - [ ] Registrar controller em Stimulus
  - [ ] Definir targets: companySelect, projectSelect
  - [ ] Definir valores: companyId

- [ ] Implementar método de carregamento de projects
  - [ ] Criar método `loadProjects()`
  - [ ] Obter company_id do target companySelect
  - [ ] Se company_id presente, fazer fetch para `/projects.json?company_id=${companyId}`
  - [ ] Se company_id vazio, fazer fetch para `/projects.json` (todos os projetos)
  - [ ] Parsear resposta JSON
  - [ ] Limpar dropdown de projects
  - [ ] Popular dropdown com options retornadas
  - [ ] Adicionar opção "Selecione um projeto" como primeira opção

- [ ] Implementar listener de mudança de company
  - [ ] Escutar evento `change` no companySelect
  - [ ] Chamar método `loadProjects()` quando company mudar
  - [ ] Limpar seleção de project quando company mudar

- [ ] Implementar feedback visual
  - [ ] Adicionar loading state durante fetch
  - [ ] Desabilitar dropdown de projects durante carregamento
  - [ ] Mostrar indicador visual (opcional)

- [ ] Criar endpoint JSON no ProjectsController
  - [ ] Adicionar rota `get :projects, to: :projects_json, defaults: { format: :json }`
  - [ ] Implementar action `projects_json`
  - [ ] Filtrar por `company_id` params se presente
  - [ ] Ordenar por nome: `Project.order(:name)`
  - [ ] Retornar array JSON com `id` e `name` de cada project

- [ ] Adicionar controller ao formulário Task
  - [ ] Adicionar `data-controller="project-selector"` ao form
  - [ ] Adicionar `data-project-selector-target="companySelect"` ao select de company
  - [ ] Adicionar `data-project-selector-target="projectSelect"` ao select de project
  - [ ] Adicionar `data-action="change->project-selector#loadProjects"` ao select de company

- [ ] Escrever testes
  - [ ] Testar carregamento de todos os projects quando nenhuma company selecionada
  - [ ] Testar filtro de projects por company_id
  - [ ] Testar limpeza de dropdown quando company muda
  - [ ] Testar performance (< 300ms)
  - [ ] Testar com company inexistente (retorna array vazio)
  - [ ] Testar system spec com interação completa
