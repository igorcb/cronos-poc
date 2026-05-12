# Deferred Work

## Deferred from: code review of 001-implementar-filtros-por-empresa-e-projeto (2026-04-01)

- **Seleção prévia de projeto não preservada após troca de empresa via Stimulus** — `project_selector_controller.js#populateProjectSelect` reconstrói o select do zero sem reaplicar `params[:project_id]`; comportamento pré-existente, fora do escopo da Story 6.1.
- **Empresa com tasks mas sem task_items excluída de `@company_monthly_totals`** — `Company.joins(tasks: :task_items)` usa INNER JOIN, omitindo empresas com tasks mas sem task_items; comportamento pré-existente do método `calculate_company_totals`.
- **Endpoint `/projects/projects.json` sem autenticação** — qualquer request JSON não autenticado pode obter a lista de projetos; pré-existente no `ProjectsController`, fora do escopo desta story.
