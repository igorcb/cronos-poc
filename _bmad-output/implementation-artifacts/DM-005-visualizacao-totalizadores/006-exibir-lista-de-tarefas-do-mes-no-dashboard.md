# Story 5.6: Exibir Lista de Tarefas do Mês no Dashboard

**Status:** ready-for-dev
**Domínio:** DM-005-visualizacao-totalizadores
**Data:** 2026-04-21
**Epic:** Epic 5 — Visualização & Totalizadores
**Story ID:** 5.6
**Story Key:** 5-6-exibir-lista-de-tarefas-do-mes-no-dashboard

---

## Story

**Como** Igor (usuário do sistema),
**Quero** ver a lista de tarefas do mês atual diretamente no dashboard,
**Para que** eu tenha uma visão consolidada do meu trabalho sem precisar navegar para `/tasks`.

---

## Contexto Técnico Crítico

### Modelos existentes
- `Task` — campos: `name`, `company_id`, `project_id`, `start_date`, `status`, `estimated_hours_hm`
- `TaskItem` — itens de tarefa com `hours_worked`
- `Company`, `Project` — associações
- **NÃO existe `TimeEntry`** — nunca usar esse nome

### Filtro de período
- Listar tarefas de `Date.current.all_month`
- **Sem filtros adicionais** no dashboard — apenas o mês atual
- **Read-only**: sem filtros, sem ações inline de editar/excluir

### Componente existente a reutilizar
- `TaskCardComponent` — renderiza `<tr>` com todas as colunas incluindo Ações
- **Atenção**: o componente atual renderiza coluna "Ações" com links de Editar/Excluir
- No dashboard a coluna Ações deve ser **omitida** (read-only)
- Opções: (a) criar partial simples sem o componente, (b) passar parâmetro `readonly: true` ao componente

### TaskCardComponent — localização
- `app/components/task_card_component.rb`
- `app/components/task_card_component.html.erb`

### Partial existente que pode ser reutilizado
- A tabela em `app/views/tasks/index.html.erb` pode ser extraída em partial `_tasks_table.html.erb`
  - Ou simplesmente replicar a estrutura da tabela no dashboard sem o componente inteiro

---

## Acceptance Criteria

- [ ] AC1: Dashboard exibe seção "Tarefas do Mês" com lista de tarefas
- [ ] AC2: Lista contém tarefas de `Date.current.all_month` (mês atual)
- [ ] AC3: Colunas exibidas: Data, Tarefa, Empresa, Projeto, Status, Estimado
- [ ] AC4: Coluna "Ações" **não aparece** no dashboard (read-only)
- [ ] AC5: Quando não há tarefas, exibe mensagem "Nenhuma tarefa este mês"
- [ ] AC6: `DashboardController#index` carrega `@tasks` com eager loading (sem N+1)
- [ ] AC7: Lista ordenada por `start_date: :desc` (mais recentes primeiro)
- [ ] AC8: Seção aparece abaixo das Quick Stats e das Ações Rápidas

---

## Dev Notes

### 1. Atualizar DashboardController

```ruby
class DashboardController < ApplicationController
  before_action :require_authentication

  def index
    @tasks = Task
      .includes(:company, :project, :task_items)
      .where(start_date: Date.current.all_month)
      .order(start_date: :desc, created_at: :desc)
  end
end
```

**Atenção**: Verificar se `require_authentication` já está como `before_action` global em `ApplicationController` ou se precisa ser adicionado explicitamente aqui.

### 2. Adicionar seção no dashboard (app/views/dashboard/index.html.erb)

Adicionar **após** a seção de Ações Rápidas:

```erb
<!-- Tarefas do Mês -->
<section aria-labelledby="tasks-month-heading">
  <div class="bg-gray-800 rounded-lg shadow-sm border border-gray-700 overflow-hidden">
    <div class="px-6 py-4 border-b border-gray-700 flex items-center justify-between">
      <h2 id="tasks-month-heading" class="text-lg font-semibold text-white">Tarefas do Mês</h2>
      <%= link_to "Ver todas", tasks_path, class: "text-sm text-blue-400 hover:text-blue-300" %>
    </div>

    <% if @tasks.empty? %>
      <div class="px-6 py-12 text-center text-gray-400" role="status">
        <p>Nenhuma tarefa este mês.</p>
      </div>
    <% else %>
      <div class="overflow-x-auto">
        <table class="min-w-full divide-y divide-gray-700" aria-label="Tarefas do mês">
          <thead class="bg-gray-900">
            <tr>
              <th scope="col" class="px-4 py-3 text-left text-xs font-medium text-gray-400 uppercase tracking-wider">Data</th>
              <th scope="col" class="px-4 py-3 text-left text-xs font-medium text-gray-400 uppercase tracking-wider">Tarefa</th>
              <th scope="col" class="px-4 py-3 text-left text-xs font-medium text-gray-400 uppercase tracking-wider">Empresa</th>
              <th scope="col" class="px-4 py-3 text-left text-xs font-medium text-gray-400 uppercase tracking-wider">Projeto</th>
              <th scope="col" class="px-4 py-3 text-left text-xs font-medium text-gray-400 uppercase tracking-wider">Status</th>
              <th scope="col" class="px-4 py-3 text-left text-xs font-medium text-gray-400 uppercase tracking-wider">Estimado</th>
            </tr>
          </thead>
          <tbody class="bg-gray-800 divide-y divide-gray-700">
            <% @tasks.each do |task| %>
              <tr class="hover:bg-gray-700 transition-colors">
                <td class="px-4 py-3 text-sm text-gray-300"><%= task.start_date&.strftime("%d/%m/%Y") %></td>
                <td class="px-4 py-3 text-sm text-white font-medium"><%= task.name %></td>
                <td class="px-4 py-3 text-sm text-gray-300"><%= task.company&.name %></td>
                <td class="px-4 py-3 text-sm text-gray-300"><%= task.project&.name %></td>
                <td class="px-4 py-3"><%= render StatusBadgeComponent.new(status: task.status.to_s) %></td>
                <td class="px-4 py-3 text-sm text-gray-300"><%= task.estimated_hours_hm %></td>
              </tr>
            <% end %>
          </tbody>
        </table>
      </div>
    <% end %>
  </div>
</section>
```

### Por que não reutilizar TaskCardComponent?

O `TaskCardComponent` renderiza a coluna "Ações" (Editar/Excluir). No dashboard queremos read-only. Criar inline na view é mais simples do que adicionar um parâmetro `readonly` ao componente — evita over-engineering para 1 use case.

### Eager loading — prevenção de N+1

O `.includes(:company, :project, :task_items)` garante que o dashboard carrega em 4 queries fixas independente do número de tarefas.

---

## Guardrails

- **NÃO** reutilizar `TaskCardComponent` — renderiza coluna Ações que não deve aparecer
- **NÃO** adicionar filtros ou interatividade — dashboard é read-only
- **NÃO** usar `Task.all` — sempre filtrar por `Date.current.all_month`
- **SEMPRE** usar `.includes(:company, :project, :task_items)` — N+1 prevention
- **NÃO** adicionar turbo-frame na listagem do dashboard — sem necessidade de update dinâmico aqui

---

## Dev Agent Record

### Checklist de Implementação
- [ ] `DashboardController#index` carrega `@tasks` com eager loading
- [ ] Seção "Tarefas do Mês" adicionada no dashboard
- [ ] Tabela sem coluna Ações (read-only)
- [ ] Empty state quando sem tarefas
- [ ] Link "Ver todas" aponta para `tasks_path`
- [ ] Sem N+1 queries

### Notas de Implementação
_(Preencher pelo dev agent)_
