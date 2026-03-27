# Arquitetura - DM-004: Registro de Tempo (Task Management)

**Domínio:** DM-004-registro-tempo
**Tipo:** Core / Principal
**Data:** 2026-01-19 (atualizado 2026-03-27)

## Visão Geral

Domínio central do sistema. Implementa o padrão **Task + TaskItems** onde Tasks são unidades gerenciáveis de trabalho e TaskItems são registros granulares de horas. Status, datas e cálculos são automáticos via callbacks.

## Modelo de Dados

```
┌──────────────────────────────────────┐
│               tasks                   │
├──────────────────────────────────────┤
│ id              : bigint PK           │
│ name            : string NOT NULL     │
│ company_id      : bigint FK NOT NULL  │
│ project_id      : bigint FK NOT NULL  │
│ start_date      : date NOT NULL       │
│ end_date        : date                │
│ status          : string NOT NULL     │
│                   default: 'pending'  │
│ delivery_date   : date                │
│ estimated_hours : decimal(10,2) NN    │
│ validated_hours : decimal(10,2)       │
│ notes           : text                │
│ created_at      : datetime            │
│ updated_at      : datetime            │
├──────────────────────────────────────┤
│ INDEX: company_id                     │
│ INDEX: project_id                     │
│ INDEX: status                         │
│ INDEX: [company_id, project_id]       │
│ FK: company_id → companies(id)        │
│ FK: project_id → projects(id)         │
└──────────────────────────────────────┘
          │ has_many :task_items
          ▼
┌──────────────────────────────────────┐
│            task_items                 │
├──────────────────────────────────────┤
│ id           : bigint PK              │
│ task_id      : bigint FK NOT NULL     │
│ start_time   : time NOT NULL          │
│ end_time     : time NOT NULL          │
│ hours_worked : decimal(10,2) NOT NULL │
│ status       : string NOT NULL        │
│                default: 'pending'     │
│ created_at   : datetime               │
│ updated_at   : datetime               │
├──────────────────────────────────────┤
│ INDEX: task_id                        │
│ INDEX: status                         │
│ INDEX: [task_id, created_at]          │
│ FK: task_id → tasks(id)               │
└──────────────────────────────────────┘
```

## Decisões Arquiteturais

### DA-030: Tasks + TaskItems (vs TimeEntries)

**Escolha:** Modelo hierárquico Task → TaskItems

**Modelo anterior descartado:**
```
Companies → Projects → TimeEntries (flat, uma linha por registro)
```

**Modelo atual:**
```
Companies → Projects → Tasks (agrupador lógico)
                          └── TaskItems (registro granular)
```

**Justificativa:**
- Tasks agrupam múltiplos períodos de trabalho na mesma atividade
- Status automático elimina gestão manual
- Horas estimadas vs validadas dá visibilidade de planejamento
- Mais alinhado com fluxo real de trabalho (tarefa = unidade, não linha de planilha)

### DA-031: Status Automático via Callbacks

**Máquina de estados:**

```
                  ┌──────────┐
    Criação ────▶ │ pending  │ ◀──── Novo TaskItem pending
                  └────┬─────┘
                       │ Último TaskItem → completed
                       ▼
                  ┌──────────┐
                  │completed │ ◀──── Último TaskItem → completed
                  └────┬─────┘
                       │ Manual (entrega ao cliente)
                       ▼
                  ┌──────────┐
                  │delivered │ ──── ESTADO FINAL (imutável)
                  └──────────┘
```

**Algoritmo:**
```ruby
def recalculate_status!
  return if delivered?  # Imutável

  latest_item = task_items.order(created_at: :desc).first
  return unless latest_item

  new_status = latest_item.completed? ? 'completed' : 'pending'
  update_column(:status, new_status) if status != new_status
end
```

**Callbacks automáticos:**
- `end_date` → preenchido quando status muda para `completed`
- `delivery_date` → preenchido quando status muda para `delivered`
- `validated_hours` → recalculado após cada save

**Justificativa:** Elimina erros humanos na gestão de status. O sistema é a fonte de verdade.

### DA-032: Cálculos Automáticos

| Cálculo | Fórmula | Trigger |
|---------|---------|---------|
| `TaskItem.hours_worked` | `(end_time - start_time) / 3600.0` | `before_save` |
| `Task.total_hours` | `task_items.sum(:hours_worked)` | Método calculado |
| `Task.calculated_value` | `company.hourly_rate * total_hours` | Método calculado |
| `Task.validated_hours` | `total_hours` | `after_save` callback |

**Tipo:** `decimal(10,2)` para todos os valores monetários e de horas.

### DA-033: Validação Tripla Camada

| Camada | Task | TaskItem |
|--------|------|----------|
| **DB** | NOT NULL em name, company_id, project_id, start_date, estimated_hours, status | NOT NULL em task_id, start_time, end_time, hours_worked, status |
| **DB** | FK constraints | FK constraint + CHECK end_time > start_time |
| **Model** | presence, inclusion, custom (project_belongs_to_company) | presence, inclusion, custom (end_time_after_start_time, task_not_delivered) |
| **Client** | Stimulus validation + required fields | Stimulus validation + required fields |

### DA-034: Imutabilidade do Status `delivered`

```ruby
# TaskItem - bloqueia criação/edição em task delivered
validate :task_must_not_be_delivered, on: [:create, :update]

def task_must_not_be_delivered
  return unless task.present?
  if task.delivered?
    errors.add(:base, "Não é possível modificar itens de tarefa já entregue")
  end
end
```

**Justificativa:** Dados entregues ao cliente são base de faturamento. Modificá-los comprometeria a confiabilidade do sistema — o pilar #1 do produto.

### DA-035: Project Selector Dinâmico

```
┌────────────┐  onChange   ┌──────────────────┐   fetch    ┌─────────────┐
│  Company   │ ──────────▶ │ Stimulus         │ ─────────▶│ /projects   │
│  Dropdown  │             │ project_selector  │           │ .json?      │
└────────────┘             │ _controller.js    │           │ company_id=X│
                           └────────┬─────────┘           └──────┬──────┘
                                    │                             │
                                    ▼                             │
                           ┌──────────────────┐                   │
                           │  Project Dropdown │ ◀────────────────┘
                           │  (atualizado)     │   JSON response
                           └──────────────────┘
```

**Performance:** Resposta < 300ms.

## Fluxo de Callbacks

```
TaskItem save
  │
  ├── before_save: calculate_hours_worked
  │     └── hours_worked = (end_time - start_time) / 3600.0
  │
  ├── [ActiveRecord save]
  │
  └── after_save: update_task_status
        └── task.recalculate_status!
              ├── Verifica último TaskItem (created_at DESC)
              ├── Atualiza status da Task
              └── after_save: recalculate_validated_hours
                    └── validated_hours = total_hours
```

## Interface com Outros Domínios

| Domínio | Interface |
|---------|-----------|
| DM-002 (Empresas) | `Task.company` → `company.hourly_rate` para `calculated_value` |
| DM-003 (Projetos) | `Task.project` → validação `project.company_id == task.company_id` |
| DM-005 (Visualização) | Eager loading: `Task.includes(:company, :project, :task_items)` |
| DM-006 (Filtros) | Scopes: `by_company`, `by_project`, `pending`, `completed`, `delivered` |
