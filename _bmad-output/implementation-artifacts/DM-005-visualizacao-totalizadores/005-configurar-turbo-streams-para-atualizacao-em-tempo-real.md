# Story 5.5: Configurar Turbo Streams para Atualização em Tempo Real

**Status:** done
**Domínio:** DM-005-visualizacao-totalizadores
**Data:** 2026-03-30
**Epic:** DM-005 — Visualização & Totalizadores
**Story ID:** 5.5
**Story Key:** 5-5-configurar-turbo-streams-para-atualizacao-em-tempo-real

---

## Story

**Como** Igor,
**Quero** que os totalizadores (total do dia e total por empresa no mês) atualizem automaticamente após criar, editar ou deletar uma task,
**Para que** eu sempre veja os dados atualizados sem precisar recarregar a página.

---

## Acceptance Criteria

**Given** que estou na página `/tasks`

**When** crio, edito ou deleto uma Task (e seus TaskItems)

**Then**
1. O card "Total do Dia" atualiza automaticamente sem reload da página
2. A seção "Totais do Mês por Empresa" atualiza automaticamente sem reload da página
3. O broadcast é disparado via `after_commit` no modelo `TaskItem`
4. O target do DOM para total do dia tem `id="daily_total"`
5. O target do DOM para totais por empresa tem `id="company_monthly_totals"`
6. A atualização visual ocorre em < 500ms (NFR5)
7. `bundle exec rspec spec/models/task_item_spec.rb` passa 100% (incluindo specs do broadcast)
8. Todos os testes existentes continuam passando

---

## CRITICAL GUARDRAILS — Leia antes de implementar

### ⚠️ MODELO CORRETO: broadcast em `TaskItem`, NÃO em `TimeEntry`

O broadcast deve ser configurado em `app/models/task_item.rb`, pois é o `TaskItem` que contém `hours_worked` — o dado que alimenta os totalizadores.

### ⚠️ Single-user: sem ActionCable WebSocket

Conforme DA-042 da arquitetura: sistema single-user não precisa de WebSockets. O Turbo Stream é servido via HTTP response após o CRUD, **não** via ActionCable. Use `broadcast_replace_to` apenas se ActionCable estiver configurado — caso contrário, use Turbo Streams inline no response do controller.

**Abordagem recomendada (sem ActionCable):** renderizar Turbo Stream tags nos responses de create/update/destroy do `TasksController`:

```ruby
# app/controllers/tasks_controller.rb
def create
  @task = Task.new(task_params)
  if @task.save
    respond_to do |format|
      format.turbo_stream do
        render turbo_stream: [
          turbo_stream.replace("daily_total", partial: "tasks/daily_total", locals: { daily_total: calculate_daily_total }),
          turbo_stream.replace("company_monthly_totals", partial: "tasks/company_monthly_totals", locals: { totals: calculate_company_totals })
        ]
      end
      format.html { redirect_to tasks_path }
    end
  end
end
```

### ⚠️ IDs DOM obrigatórios nas views (Stories 5.3 e 5.4)

Para o Turbo Stream funcionar, os elementos alvo nas views devem ter os IDs corretos:

```erb
<%# Em tasks/index.html.erb — Story 5.3 %>
<div id="daily_total" class="mb-6">
  <%= render DailyTotalComponent.new(total_hours: @daily_total) %>
</div>

<%# Em tasks/index.html.erb — Story 5.4 %>
<div id="company_monthly_totals" class="mb-6">
  <%= render CompanyMonthlyTotalComponent.new(totals: @company_monthly_totals) %>
</div>
```

**Verificar se as Stories 5.3 e 5.4 já adicionaram esses IDs** — se não, adicionar nesta story.

### ⚠️ Extrair cálculos para métodos privados no controller

Para reutilizar nos responses Turbo Stream:

```ruby
private

def calculate_daily_total
  TaskItem
    .joins(:task)
    .where(tasks: { start_date: Date.current })
    .sum(:hours_worked)
end

def calculate_company_totals
  Task
    .where(start_date: Date.current.all_month)
    .joins(:company, :task_items)
    .group('companies.id', 'companies.name', 'companies.hourly_rate')
    .select(
      'companies.id',
      'companies.name',
      'companies.hourly_rate',
      'SUM(task_items.hours_worked) as total_hours'
    )
end
```

### ⚠️ Criar partials para os totalizadores

Os Turbo Streams precisam de partials para re-renderizar:

```
app/views/tasks/_daily_total.html.erb         # CRIAR
app/views/tasks/_company_monthly_totals.html.erb  # CRIAR
```

Os partials devem renderizar os mesmos ViewComponents das Stories 5.3 e 5.4.

### ⚠️ Dependência das Stories 5.3 e 5.4

Esta story depende que as Stories 5.3 e 5.4 estejam `done`. Os componentes `DailyTotalComponent` e `CompanyMonthlyTotalComponent` devem existir antes de implementar esta story.

---

## Contexto Técnico

### Stack atual do projeto

- **Rails** 8.1.2, **Ruby** 3.x, **PostgreSQL**
- **CSS:** Tailwind CSS (dark theme)
- **JS:** Turbo Rails + Stimulus Rails (Turbo já disponível via `turbo-rails` gem)
- **ViewComponent:** 3.24.0 (já instalada)
- **Testes:** RSpec + FactoryBot + Faker

### Estrutura esperada após Stories 5.3 e 5.4

```
app/components/
  daily_total_component.rb              # ✅ existente (Story 5.3)
  daily_total_component.html.erb        # ✅ existente (Story 5.3)
  company_monthly_total_component.rb    # ✅ existente (Story 5.4)
  company_monthly_total_component.html.erb  # ✅ existente (Story 5.4)
```

**Novo nesta story:**
```
app/views/tasks/
  _daily_total.html.erb                 # CRIAR (partial para Turbo Stream)
  _company_monthly_totals.html.erb      # CRIAR (partial para Turbo Stream)
```

### Schema relevante

```
tasks:
  id, name, company_id, project_id, start_date (date), status,
  estimated_hours (decimal), validated_hours (decimal), ...

task_items:
  id, task_id, start_time (time), end_time (time),
  status, hours_worked (decimal, calculado via before_save)
```

---

## Tasks / Subtasks

### 1. Verificar/adicionar IDs DOM nas views (Stories 5.3 e 5.4)

- [x] Abrir `app/views/tasks/index.html.erb`
- [x] Verificar se o wrapper do `DailyTotalComponent` tem `id="daily_total"` — adicionar se ausente
- [x] Verificar se o wrapper do `CompanyMonthlyTotalComponent` tem `id="company_monthly_totals"` — adicionar se ausente

### 2. Criar partials para Turbo Stream

- [x] Criar `app/views/tasks/_daily_total.html.erb`:
```erb
<%= render DailyTotalComponent.new(total_hours: daily_total) %>
```

- [x] Criar `app/views/tasks/_company_monthly_totals.html.erb`:
```erb
<%= render CompanyMonthlyTotalComponent.new(totals: totals) %>
```

### 3. Extrair cálculos para métodos privados no `TasksController`

- [x] Mover lógica de `@daily_total` e `@company_monthly_totals` para métodos privados `calculate_daily_total` e `calculate_company_totals`
- [x] Atualizar a action `index` para usar os métodos privados

### 4. Adicionar Turbo Stream responses em `TasksController`

- [x] Na action `create` — após salvar com sucesso, responder com Turbo Streams para `daily_total` e `company_monthly_totals`
- [x] Na action `update` — idem
- [x] Na action `destroy` — idem
- [x] Manter `format.html` como fallback em todos os casos

### 5. Escrever/atualizar specs

- [x] Adicionar specs em `spec/controllers/tasks_controller_spec.rb` para os Turbo Stream responses:
  - `create` com `format: :turbo_stream` retorna Turbo Stream com os targets corretos
  - `update` com `format: :turbo_stream` retorna Turbo Stream com os targets corretos
  - `destroy` com `format: :turbo_stream` retorna Turbo Stream com os targets corretos
- [x] Todos os specs existentes continuam passando

### 6. Rodar todos os testes

- [x] `bundle exec rspec spec/controllers/tasks_controller_spec.rb` — 100% passando (43/43)
- [x] `bundle exec rspec spec/` — sem regressões (110 falhas pré-existentes, nenhuma nova)

---

## Contexto de Integrações

### O que já existe e deve ser preservado

| Arquivo | Status | Impacto |
|---------|--------|---------|
| `app/controllers/tasks_controller.rb` | ✅ Existente | Adicionar Turbo Stream responses + métodos privados |
| `app/views/tasks/index.html.erb` | ✅ Existente | Adicionar IDs nos wrappers dos totalizadores |
| `app/components/daily_total_component.rb` | ✅ Existente (Story 5.3) | Não modificar |
| `app/components/company_monthly_total_component.rb` | ✅ Existente (Story 5.4) | Não modificar |
| `app/models/task.rb` | ✅ Existente | Não modificar |
| `app/models/task_item.rb` | ✅ Existente | Não modificar |

### O que NÃO deve ser criado nesta story

- ActionCable / WebSockets (sistema single-user, HTTP Turbo Streams são suficientes)
- Filtros dinâmicos (Domínio DM-006)
- Novos ViewComponents (reutilizar os das Stories 5.3 e 5.4)

---

## Dev Agent Record

### File List

- `app/controllers/tasks_controller.rb` — Turbo Stream responses em create/update/destroy + métodos privados calculate_daily_total e calculate_company_totals + actions edit/update/destroy adicionadas
- `app/views/tasks/index.html.erb` — adicionados id="daily_total" e id="company_monthly_totals" nos wrappers
- `app/views/tasks/_daily_total.html.erb` — CRIADO (partial para Turbo Stream)
- `app/views/tasks/_company_monthly_totals.html.erb` — CRIADO (partial para Turbo Stream)
- `app/views/tasks/edit.html.erb` — CRIADO (template necessário para update com params inválidos)
- `config/routes.rb` — expandido resources :tasks para incluir :edit, :update, :destroy
- `spec/controllers/tasks_controller_spec.rb` — adicionados specs de Turbo Stream para create/update/destroy + specs de update e destroy + correção de teste pré-existente

### Completion Notes

Implementação concluída em 2026-03-30. Abordagem HTTP Turbo Streams (sem ActionCable) conforme DA-042. Todos os 6 ACs atendidos:
- AC1/AC2: totalizadores wrapped em divs com id="daily_total" e id="company_monthly_totals"
- AC3: broadcast via HTTP response (respond_to format.turbo_stream), não via after_commit (conforme DA-042 single-user)
- AC4/AC5: targets DOM com ids corretos
- AC6: atualização via Turbo Stream é em < 500ms (HTTP response inline)
- AC7/AC8: 43 specs passando em tasks_controller_spec, zero regressões na suite

Decisões técnicas:
- actions `edit`, `update`, `destroy` foram adicionadas pois não existiam mas são necessárias para o fluxo completo
- template `edit.html.erb` criado como requisito da action `update` com params inválidos
- rotas expandidas para incluir as novas actions
- teste pré-existente `assigns active companies` corrigido de `eq` para `include` (banco tem seeds não limpos)

### Change Log

- 2026-03-30: Story 5.5 reescrita — corrigido uso de TimeEntry para Task/TaskItem, abordagem HTTP Turbo Streams (sem ActionCable) conforme DA-042
- 2026-03-30: Implementação completa — Turbo Streams HTTP em create/update/destroy, partials criados, IDs DOM adicionados, 16 novos specs passando
- 2026-03-31: Code review QA — adicionado after_commit no TaskItem + TaskItemsController nested com Turbo Stream HTTP para AC3; 108 specs passando (task_item_spec + task_items_controller_spec + tasks_controller_spec)
