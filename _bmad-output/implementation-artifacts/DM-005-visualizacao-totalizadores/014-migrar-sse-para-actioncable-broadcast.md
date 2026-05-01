# Story 5.14: Migrar SSE para ActionCable Broadcast — Atualização em Tempo Real Cross-Tab

**Status:** done
**Domínio:** DM-005-visualizacao-totalizadores
**Data:** 2026-04-30
**Epic:** Epic 5 — Visualização & Dashboard
**Story ID:** 5.14
**Story Key:** 5-14-migrar-sse-para-actioncable-broadcast

---

## Contexto

A implementação anterior usava Server-Sent Events (SSE) via `ActionController::Live` com polling de 1s em banco de dados. Essa abordagem bloqueava threads/processos no Puma fork mode, quebrando o servidor em produção. Além disso, atualizava apenas o tab que fez a requisição — outros dashboards abertos (ex: celular + desktop) não recebiam a atualização.

---

## História do Usuário

**Como** usuário do Cronos POC,
**Quero** que qualquer dashboard aberto (em qualquer dispositivo ou aba) atualize automaticamente quando um lançamento de horas ou entrega de task acontecer,
**Para** ver os dados em tempo real sem precisar dar refresh manualmente.

---

## Critérios de Aceite

- [x] **AC1 — Remoção do SSE:** `DashboardEventsController` e `dashboard_polling_controller.js` removidos sem regressão
- [x] **AC2 — ActionCable via Turbo Streams:** dashboard assina o canal `"dashboard"` via `turbo_stream_from "dashboard"`
- [x] **AC3 — Broadcast após task_item salvo:** `after_commit` no `TaskItem` dispara `DashboardBroadcastJob`
- [x] **AC4 — Broadcast após entrega de task:** `TasksController#deliver` dispara `DashboardBroadcastJob`
- [x] **AC5 — Todos os tabs atualizam:** o broadcast via `Turbo::StreamsChannel.broadcast_render_to` propaga para todos os clientes conectados simultaneamente
- [x] **AC6 — Solid Cable em produção:** usa adaptador Solid Cable (sem Redis), já configurado em `cable.yml`

---

## Análise Técnica

### Arquitetura

```
TaskItem.after_commit → DashboardBroadcastJob.perform_later
                              ↓
              Turbo::StreamsChannel.broadcast_render_to("dashboard", ...)
                              ↓
         turbo_stream_from "dashboard" em todos os browsers conectados
```

### Arquivos Removidos

- `app/controllers/dashboard_events_controller.rb` — SSE controller com `ActionController::Live`
- `app/javascript/controllers/dashboard_polling_controller.js` — Stimulus controller com `EventSource`
- Rotas `get "dashboard/refresh"` e `get "dashboard/events"` removidas de `routes.rb`

### Arquivos Criados

**`app/channels/dashboard_channel.rb`**
```ruby
class DashboardChannel < ActionCable::Channel::Base
  def subscribed
    stream_from "dashboard"
  end
end
```

**`app/jobs/dashboard_broadcast_job.rb`**
```ruby
class DashboardBroadcastJob < ApplicationJob
  queue_as :default
  include DashboardCalculations

  def perform
    Turbo::StreamsChannel.broadcast_render_to(
      "dashboard",
      partial: "dashboard/broadcast_streams",
      locals: { ... todos os KPIs e tasks ... }
    )
  end
end
```

**`app/views/dashboard/_broadcast_streams.turbo_stream.erb`**
— Partial com extensão `.turbo_stream.erb` (obrigatório para broadcast_render_to).
Contém `turbo_stream.replace` para cada KPI card e `turbo_stream.update` para `tasks-list`.

### Modificações

- `app/models/task_item.rb` — `after_commit :broadcast_dashboard_update` → `DashboardBroadcastJob.perform_later`
- `app/controllers/tasks_controller.rb` — `#deliver` dispara `DashboardBroadcastJob.perform_later`
- `app/views/dashboard/index.html.erb` — `<%= turbo_stream_from "dashboard" %>` no topo; removido `data-controller="dashboard-polling"`

---

## Arquivos Modificados

| Arquivo | Ação |
|---------|------|
| `app/controllers/dashboard_events_controller.rb` | Removido |
| `app/javascript/controllers/dashboard_polling_controller.js` | Removido |
| `app/javascript/controllers/index.js` | Removido import do polling controller |
| `config/routes.rb` | Removidas rotas SSE |
| `app/channels/dashboard_channel.rb` | Criado |
| `app/jobs/dashboard_broadcast_job.rb` | Criado |
| `app/views/dashboard/_broadcast_streams.turbo_stream.erb` | Criado |
| `app/models/task_item.rb` | after_commit → DashboardBroadcastJob |
| `app/controllers/tasks_controller.rb` | #deliver dispara broadcast |
| `app/views/dashboard/index.html.erb` | turbo_stream_from + remoção SSE attrs |

---

## Estimativa

**2 story points** (~4h) — remoção de arquitetura + nova implementação ActionCable + testes cross-tab.

---

## Dev Agent Record

### Completion Notes

- ✅ AC1: SSE removido completamente — sem DashboardEventsController, sem EventSource JS
- ✅ AC2: `<%= turbo_stream_from "dashboard" %>` no index gera `<turbo-cable-stream-source>` que abre WebSocket
- ✅ AC3: `after_commit` no TaskItem (não `after_save`) garante broadcast só após transação confirmada
- ✅ AC4: `#deliver` no TasksController dispara `DashboardBroadcastJob.perform_later` após `update!`
- ✅ AC5: Testado com dois tabs abertos simultaneamente — ambos atualizam ao lançar horas
- ✅ AC6: Solid Cable configurado em `cable.yml` — sem dependência de Redis

### Problema Encontrado

Partial `_broadcast_streams` criado inicialmente como `.html.erb` causava `ActionView::MissingTemplate`. Corrigido renomeando para `.turbo_stream.erb` (formato exigido pelo `broadcast_render_to`).

### Change Log

- 2026-04-30: Implementação completa — SSE removido, ActionCable implementado, broadcast cross-tab funcionando
