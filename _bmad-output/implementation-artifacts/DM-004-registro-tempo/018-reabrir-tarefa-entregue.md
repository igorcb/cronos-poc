# Story 4.18: Botão Reabrir Tarefa Entregue (Reverter delivered → completed)

**Status:** ready-for-dev
**Domínio:** DM-004-registro-tempo
**Data:** 2026-05-14
**Epic:** Epic 7 — Edição & Correção
**Story ID:** 4.18
**Story Key:** 4-18-reabrir-tarefa-entregue
**Prioridade:** high

---

## Contexto

Atualmente, quando uma tarefa é entregue por engano (clique acidental no botão de entregar, ou correção necessária após entrega), não há forma de reverter — Igor precisa editar dados no banco manualmente. Story 4.17 marca campos críticos como `read-only` quando `delivered`, mas o usuário precisa de uma porta de saída segura para reverter.

Esta story adiciona um botão **"Reabrir tarefa"** disponível apenas para tarefas `delivered`, com confirmação modal, que:
1. Volta o status para `completed`
2. Limpa `delivery_date`
3. Mantém os totais de horas/valor recalculáveis dinamicamente até nova entrega

> **Por que apenas `delivered → completed` e não `delivered → pending`?** Manter a regra de status automático intacta. Se as horas validadas ainda atingem 100% do estimado, a tarefa é naturalmente `completed`; se Igor depois remover lançamentos, o callback do model levará automaticamente para `pending`.

---

## História do Usuário

**Como** Igor,
**Quero** poder reabrir uma tarefa que foi entregue por engano,
**Para** corrigir dados (lançamentos, nome, código, projeto, valor) sem precisar mexer no banco manualmente.

---

## Critérios de Aceite

### AC1 — Botão Reabrir
- [ ] **AC1.1:** Botão "Reabrir tarefa" exibido **apenas** quando `task.delivered?`
- [ ] **AC1.2:** Localização: na tela de edição (`/tasks/:id/edit`), no topo do form ou na seção "Dados Principais", próximo ao campo `status` disabled
- [ ] **AC1.3:** Estilo visual destacado (cor de aviso, ex: amarelo/laranja) para deixar claro que é ação reversiva sensível
- [ ] **AC1.4:** Ícone sugerido: 🔓 ou seta-circular (Tabler `icon-rotate`)

### AC2 — Modal de confirmação
- [ ] **AC2.1:** Click no botão abre modal Turbo Frame
- [ ] **AC2.2:** Texto do modal: **"Tem certeza que quer reabrir a tarefa?"**
- [ ] **AC2.3:** Sub-texto explicativo:
  ```
  Ao reabrir:
  • Status voltará para "Em andamento" (completed)
  • Data de entrega será limpa
  • Valor entregue será recalculado dinamicamente
  Essa ação pode ser revertida ao entregar novamente.
  ```
- [ ] **AC2.4:** Dois botões: **"Confirmar reabertura"** (primary, destrutivo) e **"Cancelar"** (secondary)
- [ ] **AC2.5:** ESC ou click no overlay fecha o modal

### AC3 — Comportamento do reopen
- [ ] **AC3.1:** Endpoint `PATCH /tasks/:id/reopen`
- [ ] **AC3.2:** Action `TasksController#reopen` valida que `@task.delivered?` (senão retorna 422 com flash)
- [ ] **AC3.3:** Operação atômica (transação):
  - `status: completed`
  - `delivery_date: nil`
  - **Não alterar** `delivered_value`, `hourly_rate`, `validated_hours` — esses ficam preservados no banco mas o `display_value` volta a ser dinâmico via `total_value` (story 5.21 já cuida disso porque verifica `delivered?`)
- [ ] **AC3.4:** Considerar limpar `delivered_value` e `hourly_rate` (snapshot) — **decisão de design**: limpar é o mais limpo (sem dados órfãos); ver Observações
- [ ] **AC3.5:** Flash de sucesso: "Tarefa reaberta com sucesso. Você pode editar os dados agora."

### AC4 — Pós-reabertura
- [ ] **AC4.1:** Após reabrir, **continua na página de edição** (`/tasks/:id/edit`)
- [ ] **AC4.2:** A página reabre com os campos antes disabled agora **habilitados** (status editável, delivery_date editável/limpa)
- [ ] **AC4.3:** O botão "Reabrir tarefa" desaparece (não está mais `delivered?`)

### AC5 — Turbo Stream / atualização cross-tela
- [ ] **AC5.1:** Reabertura atualiza via Turbo Stream os componentes do dashboard se a tarefa estiver visível (KPIs de "Entregas do Mês", "Valor Entregue", linha do task no dashboard)
- [ ] **AC5.2:** Padrão Turbo Stream já estabelecido no projeto (similar ao `deliver`)

### AC6 — Cobertura
- [ ] **AC6.1:** Request spec PATCH `/tasks/:id/reopen` em task `delivered` → status=completed, delivery_date=nil, 200
- [ ] **AC6.2:** Request spec PATCH `/tasks/:id/reopen` em task `completed` (não delivered) → 422 ou redirect com flash de erro
- [ ] **AC6.3:** Request spec PATCH `/tasks/:id/reopen` em task `pending` → 422
- [ ] **AC6.4:** System spec/Playwright: click botão → modal → confirmar → flash de sucesso → form com campos habilitados

---

## Análise Técnica

### Rotas

```ruby
# config/routes.rb
resources :tasks do
  member do
    patch :deliver    # já existe
    patch :reopen     # novo
  end
end
```

### Controller

```ruby
def reopen
  unless @task.delivered?
    redirect_to edit_task_path(@task), alert: "Apenas tarefas entregues podem ser reabertas."
    return
  end

  @task.update!(
    status: :completed,
    delivery_date: nil,
    delivered_value: nil,
    hourly_rate: nil
  )

  respond_to do |format|
    format.html { redirect_to edit_task_path(@task), notice: "Tarefa reaberta com sucesso." }
    format.turbo_stream # atualiza KPIs e linha do dashboard
  end
end
```

### View — botão na seção do status (edit.html.erb, dentro do form ou ao lado)

```erb
<% if @task.delivered? %>
  <%= link_to "Reabrir tarefa",
        reopen_modal_task_path(@task),
        data: { turbo_frame: "modal" },
        class: "..." %>
<% end %>
```

### Modal Turbo Frame

Padrão já estabelecido no projeto (`tasks/new` modal). Criar partial `app/views/tasks/_reopen_confirmation_modal.html.erb` com:
- Botão "Confirmar" que dispara `PATCH /tasks/:id/reopen`
- Botão "Cancelar" que fecha o modal
- Stimulus controller `data-controller="modal"` com action `keydown.escape`

### Turbo Streams a atualizar (similar a `deliver`)

- `kpi-entregas-mes`
- `kpi-horas-entregues`
- `kpi-valor-entregue`
- `kpi-media-por-entrega`
- `kpi-media-por-entrega-inline`
- `task-row-#{@task.id}` (badge status + valor + botões de ação)

---

## Arquivos a Criar/Modificar

| Arquivo | Ação |
|---------|------|
| `config/routes.rb` | Adicionar member `patch :reopen` |
| `app/controllers/tasks_controller.rb` | Adicionar `#reopen` + Turbo Streams |
| `app/views/tasks/edit.html.erb` | Botão "Reabrir" condicional + frame modal |
| `app/views/tasks/_reopen_confirmation_modal.html.erb` | Criar modal de confirmação |
| `app/views/tasks/reopen.turbo_stream.erb` | Streams de KPIs + task row |
| `spec/requests/tasks_spec.rb` | Specs do `#reopen` (delivered/completed/pending) |
| `spec/system/tasks_reopen_spec.rb` (opcional) | System spec do fluxo modal |

---

## Testes

- [ ] PATCH `reopen` em task delivered → status=completed, delivery_date=nil, delivered_value=nil, hourly_rate=nil
- [ ] PATCH `reopen` em task não-delivered → 422/redirect com alert
- [ ] View edit de task delivered → contém link "Reabrir tarefa"
- [ ] View edit de task completed → **não** contém link "Reabrir tarefa"
- [ ] System test: click → modal abre com texto correto → confirmar → fica na mesma página, status agora habilitado
- [ ] System test: click → modal abre → cancelar → modal fecha, nada muda

---

## Observações

### Por que limpar `delivered_value` e `hourly_rate` no reopen?

**Argumento a favor (decisão recomendada):**
- `display_value` (story 5.21) usa `delivered? ? delivered_value : total_value` — se a tarefa volta para `completed`, deve passar a usar `total_value` dinâmico. Limpar o snapshot evita confusão em queries que usam o campo direto.
- Dados ficam consistentes: tarefa `completed` nunca tem `delivered_value` preenchido.

**Argumento contra:**
- Perde histórico do snapshot da última entrega.

**Decisão:** **limpar** — manter consistência prevalece. Se Igor entregar de novo, o callback `update_delivery_date` (story 4.15) repopula o snapshot.

### Auditoria futura (fora de escopo)

Se quisermos rastrear quem/quando reabriu, criar tabela `task_audit_logs` (ex: `audited` gem ou tabela custom). Por enquanto, registrar no `Rails.logger` é suficiente.

### Padrão consagrado

Diversos ERPs (Trello, Jira, Asana) usam esse padrão "Reopen" com modal de confirmação. UX validada: 2 cliques deliberados (botão + confirm) impedem acidente.

---

## Dependências

- Story 4.17 (form edit completo) — relacionada mas independente; ambas podem rodar em paralelo
- Stories 4.15 (delivered_value snapshot) e 5.21 (display_value) — **já implementadas**
- Padrão Turbo Stream do `deliver` — **já estabelecido**

---

## Estimativa

**2 story points** (~3h) — rota + action + modal Turbo Frame + Turbo Streams (similar ao deliver já implementado) + specs.
