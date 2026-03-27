# Story 4.5: Implementar Project Selector Dinâmico com Stimulus

Status: done

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

- [x] Criar Stimulus controller `project_selector_controller.js`
  - [x] Criar arquivo `app/javascript/controllers/project_selector_controller.js`
  - [x] Registrar controller em Stimulus
  - [x] Definir targets: companySelect, projectSelect
  - [x] Definir valores: companyId

- [x] Implementar método de carregamento de projects
  - [x] Criar método `loadProjects()`
  - [x] Obter company_id do target companySelect
  - [x] Se company_id presente, fazer fetch para `/projects.json?company_id=${companyId}`
  - [x] Se company_id vazio, fazer fetch para `/projects.json` (todos os projetos)
  - [x] Parsear resposta JSON
  - [x] Limpar dropdown de projects
  - [x] Popular dropdown com options retornadas
  - [x] Adicionar opção "Selecione um projeto" como primeira opção

- [x] Implementar listener de mudança de company
  - [x] Escutar evento `change` no companySelect
  - [x] Chamar método `loadProjects()` quando company mudar
  - [x] Limpar seleção de project quando company mudar

- [x] Implementar feedback visual
  - [x] Adicionar loading state durante fetch
  - [x] Desabilitar dropdown de projects durante carregamento
  - [x] Mostrar indicador visual (opcional)

- [x] Criar endpoint JSON no ProjectsController
  - [x] Adicionar rota `get :projects, to: :projects_json, defaults: { format: :json }`
  - [x] Implementar action `projects_json`
  - [x] Filtrar por `company_id` params se presente
  - [x] Ordenar por nome: `Project.order(:name)`
  - [x] Retornar array JSON com `id` e `name` de cada project

- [x] Adicionar controller ao formulário Task
  - [x] Adicionar `data-controller="project-selector"` ao form
  - [x] Adicionar `data-project-selector-target="companySelect"` ao select de company
  - [x] Adicionar `data-project-selector-target="projectSelect"` ao select de project
  - [x] Adicionar `data-action="change->project-selector#loadProjects"` ao select de company

- [x] Escrever testes
  - [x] Testar carregamento de todos os projects quando nenhuma company selecionada
  - [x] Testar filtro de projects por company_id
  - [x] Testar limpeza de dropdown quando company muda
  - [x] Testar performance (< 300ms)
  - [x] Testar com company inexistente (retorna array vazio)
  - [x] Testar system spec com interação completa
