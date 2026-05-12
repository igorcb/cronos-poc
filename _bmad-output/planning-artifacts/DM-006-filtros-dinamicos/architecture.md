# Arquitetura - DM-006: Filtros Dinâmicos

**Domínio:** DM-006-filtros-dinamicos
**Tipo:** Consumo / Interação
**Data:** 2025-12-26 (atualizado 2026-03-27)

## Visão Geral

Filtros são a interface entre o usuário e os dados agregados. A arquitetura combina Stimulus (estado client-side) com Turbo Frames (atualização parcial server-side) para entregar filtros instantâneos sem JavaScript pesado.

## Arquitetura de Filtros

```
┌─────────────────────────────────────────────────────┐
│                     Browser                          │
│                                                      │
│  ┌──────────────────────────────────────────────┐   │
│  │          Stimulus filter_controller           │   │
│  │                                               │   │
│  │  [Empresa ▼] [Projeto ▼] [Status ▼] [Período]│   │
│  │                                               │   │
│  │  onChange → atualiza URL params                │   │
│  │           → submete Turbo Frame               │   │
│  └──────────────────┬───────────────────────────┘   │
│                     │                                │
│  ┌──────────────────▼───────────────────────────┐   │
│  │         Turbo Frame: "filtered_results"       │   │
│  │                                               │   │
│  │  ┌─────────────┐  ┌──────────────────────┐   │   │
│  │  │ Totalizadores│  │ Lista de Tasks       │   │   │
│  │  │ (recalculados)│  │ (filtradas)          │   │   │
│  │  └─────────────┘  └──────────────────────┘   │   │
│  └──────────────────────────────────────────────┘   │
└─────────────────────────────────────────────────────┘
          │
          │ GET /tasks?company_id=1&status=pending&period=current_month
          ▼
┌─────────────────────────────────────────────────────┐
│                  Rails Controller                    │
│                                                      │
│  @tasks = Task.includes(:company, :project, :items) │
│  @tasks = @tasks.by_company(params[:company_id])    │
│  @tasks = @tasks.by_status(params[:status])          │
│  @tasks = @tasks.by_period(params[:start], :end)    │
│                                                      │
│  respond_to turbo_frame / html                       │
└─────────────────────────────────────────────────────┘
```

## Decisões Arquiteturais

### DA-050: Stimulus + Turbo Frames (vs JavaScript puro)

**Escolha:** Stimulus controllers gerenciam estado, Turbo Frames atualizam resultados

**Alternativas descartadas:**
- JavaScript puro com fetch + DOM manipulation — frágil, difícil de manter
- StimulusReflex — overhead de WebSocket desnecessário
- Filtro server-side com full page reload — UX ruim, lento

**Implementação:**
```javascript
// app/javascript/controllers/filter_controller.js
import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["company", "project", "status", "startDate", "endDate", "form"]

  filter() {
    // Submete form via Turbo Frame
    this.formTarget.requestSubmit()
  }

  companyChanged() {
    // Atualiza dropdown de projetos (reutiliza project_selector)
    // Depois filtra
    this.filter()
  }
}
```

**Justificativa:** Hotwire é o padrão Rails 8. Stimulus é leve (~2KB), Turbo Frames evita reload completo. Zero dependências extras.

### DA-051: Filtros Combináveis via Query Params

**Escolha:** Filtros compostos via URL query params

```
/tasks                                    # Sem filtro (mês atual)
/tasks?company_id=1                       # Por empresa
/tasks?company_id=1&status=pending        # Empresa + Status
/tasks?company_id=1&status=pending&period=last_7_days  # Triplo
```

**Controller pattern:**
```ruby
class TasksController < ApplicationController
  def index
    @tasks = Task.includes(:company, :project, :task_items)
    @tasks = @tasks.by_company(params[:company_id]) if params[:company_id].present?
    @tasks = @tasks.by_project(params[:project_id]) if params[:project_id].present?
    @tasks = @tasks.where(status: params[:status]) if params[:status].present?
    @tasks = apply_period_filter(@tasks)
    @tasks = @tasks.order(start_date: :desc)

    @totals = calculate_totals(@tasks)
  end
end
```

**Justificativa:** Query params são bookmarkable, shareable, e compatíveis com Turbo Frames nativamente.

### DA-052: Presets de Período

| Preset | Query |
|--------|-------|
| `current_month` | `start_date: Date.today.beginning_of_month..Date.today.end_of_month` |
| `last_month` | `start_date: 1.month.ago.beginning_of_month..1.month.ago.end_of_month` |
| `last_7_days` | `start_date: 7.days.ago..Date.today` |
| `current_week` | `start_date: Date.today.beginning_of_week..Date.today.end_of_week` |
| `custom` | `start_date: params[:start_date]..params[:end_date]` |

**Default:** `current_month` quando nenhum período selecionado.

### DA-053: Recálculo de Totalizadores

**Escolha:** Totalizadores são recalculados server-side a cada filtro

```ruby
def calculate_totals(tasks)
  {
    total_hours: tasks.joins(:task_items).sum('task_items.hours_worked'),
    total_value: tasks.sum { |t| t.calculated_value },
    by_company: tasks.joins(:company, :task_items)
                     .group('companies.name')
                     .sum('task_items.hours_worked')
  }
end
```

**Justificativa:** Cálculos server-side são mais confiáveis e consistentes. A performance é garantida pelos índices compostos existentes.

## Índices Utilizados

| Query | Índice |
|-------|--------|
| `WHERE company_id = ?` | `tasks.company_id` |
| `WHERE project_id = ?` | `tasks.project_id` |
| `WHERE status = ?` | `tasks.status` |
| `WHERE start_date BETWEEN ? AND ?` | Range scan na PK (ou índice em start_date) |
| `GROUP BY company_id` | `tasks.company_id` |
| `JOIN task_items ON task_id` | `task_items.task_id` |

## Performance

| Operação | Meta | Garantia |
|----------|------|----------|
| Aplicar filtro | < 1s | Turbo Frame parcial + índices |
| Recalcular totais | < 500ms | Queries agregadas otimizadas |
| Mudar dropdown | < 300ms | Stimulus local + submit |

## Interface com Outros Domínios

| Domínio | Interação |
|---------|-----------|
| DM-004 (Registro) | Scopes: `by_company`, `by_project`, `pending`, `completed`, `delivered` |
| DM-005 (Visualização) | Mesmos ViewComponents renderizam resultados filtrados |
| DM-002 (Empresas) | `Company.active` popula dropdown de filtro |
| DM-003 (Projetos) | `Project.where(company_id:)` popula dropdown dinâmico |
