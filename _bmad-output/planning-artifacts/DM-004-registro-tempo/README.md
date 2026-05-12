# DM-004: Registro de Tempo (Task Management)

**Domínio:** Core / Principal
**Epics Relacionados:** Epic 4, Epic 7
**Status:** Em Progresso

## Descrição

Domínio central do sistema. Responsável pelo registro e gestão de tarefas com tracking automático de tempo. Substituiu o conceito original de TimeEntries (timesheet simples) por um sistema de Tasks + TaskItems com status automático e cálculos integrados.

## Entidades

| Entidade | Tabela | Descrição |
|----------|--------|-----------|
| Task | `tasks` | Tarefa gerenciável com status automático e valores calculados |
| TaskItem | `task_items` | Registro granular de horas trabalhadas em uma tarefa |

### Schema: tasks

| Coluna | Tipo | Restrições | Descrição |
|--------|------|------------|-----------|
| `name` | string | NOT NULL | Nome da tarefa |
| `company_id` | integer | NOT NULL, FK | Empresa associada |
| `project_id` | integer | NOT NULL, FK | Projeto associado |
| `start_date` | date | NOT NULL | Data de início (manual) |
| `end_date` | date | nullable | Data de término (automática quando completed) |
| `status` | string | NOT NULL, default: 'pending' | Status: pending, completed, delivered |
| `delivery_date` | date | nullable | Data de entrega (automática quando delivered) |
| `estimated_hours` | decimal(10,2) | NOT NULL | Horas estimadas (manual) |
| `validated_hours` | decimal(10,2) | nullable | Horas reais (calculado) |
| `notes` | text | nullable | Observações gerais |

### Schema: task_items

| Coluna | Tipo | Restrições | Descrição |
|--------|------|------------|-----------|
| `task_id` | integer | NOT NULL, FK | Tarefa pai |
| `start_time` | time | NOT NULL | Hora de início |
| `end_time` | time | NOT NULL | Hora de término |
| `hours_worked` | decimal(10,2) | NOT NULL | Duração calculada automaticamente |
| `status` | string | NOT NULL, default: 'pending' | Status: pending, completed |

### Índices
- tasks: `company_id`, `project_id`, `status`, `[company_id, project_id]`
- task_items: `task_id`, `status`, `[task_id, created_at]`

## Regras de Negócio

### Validações
1. **Consistência Company-Project:** `project.company_id` deve ser igual a `task.company_id`
2. **Validação Temporal:** `end_time` deve ser posterior a `start_time` (TaskItem)
3. **Imutabilidade Delivered:** TaskItems não podem ser criados/editados em Tasks com status `delivered`
4. **Validação Tripla Camada:** Constraints no banco + validações ActiveRecord + validação client-side

### Status Automático
5. **Recálculo de Status:** Task status é recalculado baseado no **último TaskItem criado** (created_at DESC)
   - Se último TaskItem está `completed` → Task fica `completed`
   - Se último TaskItem está `pending` → Task fica `pending`
6. **Delivered é Imutável:** Task com status `delivered` NÃO recalcula status
7. **end_date Automático:** Preenchido automaticamente quando status muda para `completed`
8. **delivery_date Automático:** Preenchido automaticamente quando status muda para `delivered`

### Cálculos
9. **hours_worked (TaskItem):** Calculado automaticamente: `(end_time - start_time) / 3600.0`
10. **total_hours (Task):** Soma de `task_items.sum(:hours_worked)`
11. **calculated_value (Task):** `company.hourly_rate * total_hours`
12. **validated_hours (Task):** Recalculado via callback após cada save

### Selector Dinâmico
13. **Filtro de Projetos:** Ao selecionar empresa no dropdown, projetos são filtrados via Stimulus (`/projects.json?company_id=X`)

## Relacionamentos

```
Task
├── belongs_to :company
├── belongs_to :project
├── has_many :task_items, dependent: :destroy
├── total_hours → task_items.sum(:hours_worked)
└── calculated_value → company.hourly_rate * total_hours

TaskItem
├── belongs_to :task
├── before_save :calculate_hours_worked
├── after_save :update_task_status
└── after_destroy :update_task_status
```

## Mudança Arquitetural

**Original (TimeEntries):**
```
Companies → Projects → TimeEntries (registro simples)
```

**Atual (Tasks + TaskItems):**
```
Companies → Projects → Tasks (gerenciáveis)
                        ├── Status automático
                        ├── Valores calculados
                        └── TaskItems (registro granular)
```

## Requisitos Cobertos

### Funcionais
- FR1: Registro de entradas de tempo
- FR2: Status (Pendente, Finalizado, Entregue)
- FR5: Cálculo automático de tempo trabalhado
- FR6: Cálculo automático de valor monetário
- FR16: Edição de entradas existentes
- FR17: Deleção de entradas incorretas

### Arquiteturais
- ARQ17-ARQ21: Validação tripla camada
- ARQ24-ARQ27: Modelagem de dados (desnormalização, decimal)
- ARQ40-ARQ42: Concerns, Service Objects

### Não-Funcionais
- NFR10-NFR13: Precisão de cálculos, validação, persistência

## Stories

### Epic 4: Task Management System

| Story | Nome | Status |
|-------|------|--------|
| 4.0 | Task Management Specification | Concluído |
| 4.1 | Criar Model Task com Validações Tripla Camada | Concluído |
| 4.2 | Criar Model TaskItem com Validações e Cálculos | Concluído |
| 4.3 | Implementar Lógica de Status Automático e Cálculos | Concluído |
| 4.4 | Implementar CRUD de Tasks (New/Create) | Concluído |
| 4.5 | Implementar Project Selector Dinâmico com Stimulus | Concluído |
| 4.6 | Criar Factories e Testes para Task e TaskItem | Concluído |

### Epic 7: Edição e Correção de Entradas

| Story | Nome | Status |
|-------|------|--------|
| 7.1 | Implementar Edit/Update de TimeEntries | Pendente |
| 7.2 | Implementar Destroy de TimeEntries com Confirmação | Pendente |
| 7.3 | Criar Testes de System para Fluxo Completo | Pendente |
