# Story 4.16: Bug Fix — Combobox Projeto Desabilitado ao Abrir Tela de Edição de Tarefa

**Status:** done
**Domínio:** DM-004-registro-tempo
**Data:** 2026-05-14
**Epic:** Epic 7 — Edição & Correção
**Story ID:** 4.16
**Story Key:** 4-16-fix-task-edit-project-disabled-on-load
**Tipo:** Bug fix
**Prioridade:** high

---

## Contexto

Ao abrir a tela de edição de tarefa (`/tasks/:id/edit`), o combobox **Projeto** carrega **desabilitado** mesmo quando a empresa já está selecionada (caso default de toda edição). Isso obriga o usuário a:

1. Reselecionar a mesma empresa no combobox Empresa (para disparar o `change` do Stimulus)
2. Aguardar o AJAX carregar os projetos
3. Reselecionar o projeto

Se o usuário tenta salvar sem fazer esse "ritual", o backend retorna erro de validação **"Projeto não pode ficar em branco"** porque o `select` desabilitado não envia valor no `params`.

**Reproduzido via Playwright MCP em 2026-05-14**, na tarefa `99999 - Tarefa Editada via Playwright MCP` (task_id 6778). Ver screenshot em `.playwright-mcp/task-edit-save-attempt.png`.

---

## Comportamento Atual (Bug)

1. Usuário clica em "Editar" em uma tarefa qualquer
2. Form abre com **Empresa selecionada** e **Projeto desabilitado/vazio**
3. Usuário altera apenas o Nome → clica "Salvar Alterações"
4. ❌ Erro: "Projeto não pode ficar em branco"
5. Campo Código também é resetado na re-renderização (perde valor preenchido)

---

## Comportamento Esperado

1. Usuário clica em "Editar"
2. Form abre com **Empresa selecionada** e **Projeto habilitado + selecionado** (do banco)
3. Usuário altera campos → clica "Salvar Alterações"
4. ✅ Tarefa atualizada com sucesso

---

## História do Usuário

**Como** Igor,
**Quero** que ao abrir a edição de uma tarefa, o combobox Projeto já apareça habilitado com o projeto atual selecionado,
**Para** poder editar apenas o que preciso sem ter que re-selecionar empresa+projeto manualmente em toda edição.

---

## Critérios de Aceite

- [x] **AC1:** Ao abrir `/tasks/:id/edit`, o combobox Projeto está **habilitado** (não `disabled`)
- [x] **AC2:** Ao abrir `/tasks/:id/edit`, o combobox Projeto já vem populado com os projetos da empresa atual do `@task`
- [x] **AC3:** O projeto atual da `@task` aparece **selecionado** no combobox
- [x] **AC4:** Editar apenas o nome (sem tocar Empresa/Projeto) → salva com sucesso (sem validação "Projeto não pode ficar em branco")
- [x] **AC5:** Trocar Empresa → combobox Projeto continua reagindo como antes (atualiza opções via AJAX) — comportamento preservado (Stimulus `project_selector_controller` inalterado)
- [x] **AC6:** Spec de request: GET `/tasks/:id/edit` retorna form com `select#task_project_id` sem atributo `disabled` e com `option[selected]` correspondente ao `task.project_id`
- [x] **AC7:** Spec de request PATCH: editar campo Nome → 302 redirect e nome atualizado

---

## Dev Agent Record

**Implementação (Opção A — server-side):**
- `app/controllers/tasks_controller.rb#edit`: adicionado `@projects = @task.company&.projects&.order(:name) || []`
- `app/controllers/tasks_controller.rb#update` (branch de erro): mesma atribuição para preservar @projects no re-render
- `app/views/tasks/edit.html.erb`: substituído `f.select :project_id, []` `disabled: true` por `f.collection_select :project_id, @projects, :id, :name, { prompt:, selected: @task.project_id }` (sem disabled)
- `spec/requests/tasks_spec.rb`: +4 specs (AC1, AC2, AC3, AC4)

**Resultado:** 38/38 specs em tasks_spec passam.

## File List

- app/controllers/tasks_controller.rb (modified)
- app/views/tasks/edit.html.erb (modified)
- spec/requests/tasks_spec.rb (modified)

---

## Análise Técnica

### Onde está o problema

Investigar dois pontos:

1. **`app/views/tasks/edit.html.erb`** — provável: combobox Projeto renderiza com `disabled: true` por padrão, dependendo do Stimulus para habilitar via JS após carregar empresa
2. **`app/javascript/controllers/project_selector_controller.js`** (ou similar) — provável: `connect()` não dispara o load inicial dos projetos quando a empresa já está pré-selecionada (só reage a `change`)

### Solução proposta

**Opção A (server-side, recomendada):**
No `tasks/edit.html.erb`, renderizar o `select` de Projeto já populado com os projetos da empresa atual e **sem** `disabled`:

```erb
<%= form.collection_select :project_id,
      @task.company&.projects || [],
      :id, :name,
      { selected: @task.project_id, prompt: "Selecione um projeto" },
      { required: true, "data-project-selector-target": "select" } %>
```

E garantir que o `TasksController#edit` carrega `@task.company.projects` (ou via decorator).

**Opção B (client-side):**
No `project_selector_controller.js#connect()`, se houver `data-initial-company-id` no companies-select, disparar o fetch dos projetos imediatamente após a montagem do controller.

Recomendação: **Opção A** — mais simples, sem dependência de JS para o estado inicial, e funciona com JS desabilitado.

---

## Arquivos a Modificar

| Arquivo | Ação |
|---------|------|
| `app/views/tasks/edit.html.erb` | Renderizar combobox Projeto pré-populado com projects da empresa atual |
| `app/controllers/tasks_controller.rb` | Garantir que `#edit` carrega `@projects = @task.company.projects` (se necessário) |
| `app/javascript/controllers/project_selector_controller.js` | Revisar `connect()` para não desabilitar quando já há valor inicial |
| `spec/requests/tasks_spec.rb` | Spec GET `#edit` — combobox sem `disabled` e com opção selecionada |
| `spec/system/tasks_edit_spec.rb` (se existir) | System test do fluxo "editar nome → salvar" sem mexer em empresa/projeto |

---

## Testes

- [ ] Spec GET `/tasks/:id/edit` — `response.body` **não** contém `<select id="task_project_id" ... disabled>`
- [ ] Spec GET `/tasks/:id/edit` — `response.body` contém `<option value="X" selected>` onde X é `@task.project_id`
- [ ] System test: editar apenas o nome → form submit → flash "Tarefa atualizada com sucesso"
- [ ] System test: trocar empresa → projetos atualizam via AJAX (regression)

---

## Reprodução do Bug (Playwright MCP)

```
1. Login como admin@cronos-poc.local
2. Navigate /tasks
3. Click "Editar" na primeira tarefa (ex: tasks/6778/edit)
4. Snapshot mostra: combobox Projeto com atributo [disabled] e alert "não pode ficar em branco"
5. Alterar apenas o Nome
6. Click "Salvar Alterações"
7. ❌ Permanece em /tasks/6778/edit com erros
```

Screenshot do bug: `.playwright-mcp/task-edit-save-attempt.png`

---

## Estimativa

**1 story point** (~2h) — investigação no view+controller+JS + 1 spec request + 1 spec system + correção cirúrgica.

---

## Observações

- Form de **criação** (`tasks/new.html.erb`) tem o mesmo combobox Projeto mas sem esse bug — porque a empresa começa sem seleção, o disabled inicial faz sentido lá
- O bug afeta **toda edição** de tarefa (qualquer empresa, qualquer projeto) — não é caso isolado
- Severidade real: usuários acabam achando que "tem que reselecionar tudo" e isso vira processo manual — UX degradada
