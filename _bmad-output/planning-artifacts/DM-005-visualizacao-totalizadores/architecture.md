# Arquitetura - DM-005: Visualização & Totalizadores

**Domínio:** DM-005-visualizacao-totalizadores
**Tipo:** Consumo / Apresentação
**Data:** 2025-12-26 (atualizado 2026-03-27)

## Visão Geral

Domínio de leitura e apresentação de dados. Todas as queries são de leitura, otimizadas com eager loading e índices compostos. A arquitetura separa claramente a renderização (ViewComponents) da atualização dinâmica (Turbo Streams).

## Arquitetura de Apresentação

```
┌─────────────────────────────────────────────────────┐
│                     Browser                          │
│                                                      │
│  ┌──────────────┐  ┌──────────────┐  ┌────────────┐│
│  │ Task Cards   │  │ Totalizadores│  │  Filtros   ││
│  │ (ViewComp.)  │  │ (ViewComp.)  │  │ (Stimulus) ││
│  └──────┬───────┘  └──────┬───────┘  └─────┬──────┘│
│         │                 │                  │       │
│         │     Turbo Streams (after CRUD)     │       │
│         │                 │                  │       │
└─────────┼─────────────────┼──────────────────┼───────┘
          ▼                 ▼                  ▼
┌─────────────────────────────────────────────────────┐
│                  Rails Controller                    │
│                                                      │
│  Task.includes(:company, :project, :task_items)     │
│       .where(start_date: month_range)                │
│       .order(start_date: :desc)                      │
└─────────────────────────────────────────────────────┘
```

## Decisões Arquiteturais

### DA-040: Eager Loading Obrigatório

**Escolha:** `includes(:company, :project, :task_items)` em toda listagem

**Query sem eager loading (N+1):**
```
SELECT * FROM tasks WHERE ...        # 1 query
SELECT * FROM companies WHERE id=1   # N queries
SELECT * FROM projects WHERE id=1    # N queries
SELECT * FROM task_items WHERE ...   # N queries
= 1 + 3N queries
```

**Query com eager loading:**
```
SELECT * FROM tasks WHERE ...
SELECT * FROM companies WHERE id IN (...)
SELECT * FROM projects WHERE id IN (...)
SELECT * FROM task_items WHERE task_id IN (...)
= 4 queries (sempre)
```

**Detecção:** Bullet gem configurada em development para alertar N+1.

### DA-041: ViewComponent para UI

**Escolha:** `view_component` gem em vez de partials tradicionais

| Component | Responsabilidade |
|-----------|-----------------|
| `TaskCardComponent` | Renderiza card individual de task com status, horas, valor |
| `StatusBadgeComponent` | Badge colorido por status (pending=amarelo, completed=verde, delivered=azul) |
| `TotalizerComponent` | Exibe total formatado (horas ou R$) |
| `DailyTotalComponent` | Soma de horas do dia |
| `CompanyMonthlyTotalComponent` | Horas e valor por empresa no mês |

**Justificativa:**
- Testáveis isoladamente (`spec/components/`)
- Encapsulam lógica de apresentação
- Performance superior a partials (caching nativo)
- Reutilizáveis entre views

**Exemplo:**
```ruby
class TaskCardComponent < ViewComponent::Base
  attr_reader :task

  def initialize(task:)
    @task = task
  end

  def status_class
    { 'pending' => 'bg-yellow-100 text-yellow-800',
      'completed' => 'bg-green-100 text-green-800',
      'delivered' => 'bg-blue-100 text-blue-800' }[task.status]
  end

  def formatted_value
    "R$ #{task.calculated_value.to_f.round(2)}"
  end
end
```

### DA-042: Turbo Streams para Atualização Real-Time

**Escolha:** Turbo Streams para atualizar totalizadores sem reload

```
TaskItem criado/editado/deletado
    │
    ├── after_commit :broadcast_totals_update
    │
    ▼
┌──────────────────────┐
│ Turbo Stream          │
│ broadcast_replace_to  │
│ "totals_stream"       │
├──────────────────────┤
│ target: daily_total   │
│ target: company_total │
│ target: task_card     │
└──────────────────────┘
    │
    ▼
Browser atualiza apenas os elementos alvo
(sem full page reload)
```

**Justificativa:** Single-user não precisa de WebSockets. Turbo Streams via HTTP é suficiente e mais simples.

### DA-043: Queries de Agregação

**Total do dia:**
```ruby
TaskItem.joins(:task)
  .where(tasks: { start_date: Date.today })
  .sum(:hours_worked)
```

**Total por empresa no mês:**
```ruby
Task.where(start_date: month_range)
  .joins(:company, :task_items)
  .group('companies.id', 'companies.name', 'companies.hourly_rate')
  .select(
    'companies.id',
    'companies.name',
    'companies.hourly_rate',
    'SUM(task_items.hours_worked) as total_hours'
  )
```

**Índices utilizados:**
- `tasks.company_id` — GROUP BY company
- `tasks.start_date` — filtro por mês (via range)
- `task_items.task_id` — JOIN com tasks
- `[company_id, project_id]` — compostos

### DA-044: Paginação Condicional

**Escolha:** Implementar paginação apenas se > 200 entradas

**Justificativa:** Para o MVP single-user, é improvável ultrapassar 200 tasks/mês. Paginação prematura adiciona complexidade sem benefício. Se necessário, `pagy` gem (mais performante que kaminari/will_paginate).

## Metas de Performance

| Métrica | Meta | Estratégia |
|---------|------|-----------|
| Listagem do mês | < 2s | Eager loading + índices |
| First Contentful Paint | < 1.5s | Server-rendered, sem SPA |
| Time to Interactive | < 3s | Stimulus leve |
| Atualização de totais | Imediata | Turbo Streams |

## Interface com Outros Domínios

| Domínio Fonte | Dados Consumidos |
|---------------|------------------|
| DM-002 (Empresas) | `company.name`, `company.hourly_rate` para totais |
| DM-003 (Projetos) | `project.name` para exibição |
| DM-004 (Registro) | Tasks + TaskItems — dados primários |
| DM-006 (Filtros) | Resultados filtrados alimentam os mesmos componentes |
