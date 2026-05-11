# Story 4.14: Substituir Campo Horas Estimadas por time_field

**Status:** done
**Domínio:** DM-004-registro-tempo
**Data:** 2026-05-07
**Epic:** Epic 4 — Task Management
**Story ID:** 4.14
**Story Key:** 4-14-campo-horas-estimadas-time-field

---

## Contexto

O formulário de criar/editar tarefa usa um `text_field` com formato livre `HH:MM` para as horas estimadas. O formulário de lançamento de horas usa `time_field` (input nativo do browser), que oferece melhor UX: seletor visual no mobile, validação nativa, consistência com o restante do sistema.

O objetivo é padronizar o campo de horas estimadas para `time_field`, igual ao campo de hora início/fim do lançamento.

---

## História do Usuário

**Como** Igor,
**Quero** usar um campo de horário nativo (time_field) para preencher as horas estimadas ao criar/editar uma tarefa,
**Para** ter a mesma experiência de entrada de dados que uso no lançamento de horas, sem precisar lembrar o formato `HH:MM`.

---

## Critérios de Aceite

- [x] **AC1:** Campo "Horas Estimadas" em `tasks/new.html.erb` (modal e versão normal) usa `time_field` no lugar de `text_field`
- [x] **AC2:** Campo "Horas Estimadas" em `tasks/edit.html.erb` usa `time_field` no lugar de `text_field`
- [x] **AC3:** O label é simplificado para "Horas Estimadas" (sem o sufixo `(HH:MM)`)
- [x] **AC4:** O hint de formato (`Formato: HH:MM (ex: 03:00, 02:30, 18:00)`) é removido — o `time_field` nativo dispensa instrução
- [x] **AC5:** Validações existentes no model (`estimated_hours_hm_must_be_valid`) continuam funcionando — o `time_field` entrega valor no formato `HH:MM` compatível com o parser atual
- [x] **AC6:** Testes existentes passam sem regressão — 34 examples, 0 failures

---

## Análise Técnica

### Mudança no campo

```erb
<%# antes — text_field %>
<%= f.text_field :estimated_hours_hm,
    placeholder: "03:00",
    pattern: "\\d{1,2}:\\d{2}",
    inputmode: "numeric",
    title: "Formato HH:MM (ex: 03:00, 02:30, 18:00)",
    ... %>
<p id="estimated-hours-hint" class="mt-1 text-xs text-gray-400">Formato: HH:MM (ex: 03:00, 02:30, 18:00)</p>

<%# depois — time_field %>
<%= f.time_field :estimated_hours_hm,
    ... %>
```

### Compatibilidade com o model

O `time_field` entrega valor no formato `HH:MM` (ex: `"03:30"`), exatamente o que o método `hm_to_decimal` no model já espera. **Nenhuma mudança no model necessária.**

### Atenção: valor inicial no `time_field`

O `time_field` espera um valor no formato `HH:MM`. O método `estimated_hours_hm` do model já retorna nesse formato via `after_find`. Sem necessidade de conversão adicional.

---

## Arquivos a Modificar

| Arquivo | Ação |
|---------|------|
| `app/views/tasks/new.html.erb` | Substituir `text_field` por `time_field` em ambas as versões (modal + normal) — remover `placeholder`, `pattern`, `inputmode`, `title` e hint de formato |
| `app/views/tasks/edit.html.erb` | Substituir `text_field` por `time_field` — remover hint de formato |

---

## Testes

- [ ] Verificar que specs existentes em `spec/requests/` passam sem regressão
- [ ] Verificar visualmente que o campo exibe o seletor nativo no browser

---

## Dependências

- `Task#estimated_hours_hm` — **já existe**, retorna `HH:MM`
- `Task#hm_to_decimal` — **já existe**, parseia `HH:MM`
- Validação `estimated_hours_hm_must_be_valid` — **já existe**, compatível com output do `time_field`

---

## Estimativa

**0,5 story points** (~1h) — substituição cirúrgica em 2 arquivos de view, sem mudança de model ou controller.

---

## Dev Agent Record

**Implementado por:** Amelia (bmad-agent-dev)
**Data:** 2026-05-11
**Branch:** feature-4-14-campo-horas-estimadas-time-field

### Arquivos Modificados

| Arquivo | Mudança |
|---------|---------|
| `app/views/tasks/new.html.erb` | `text_field` → `time_field` em modal e versão normal; label simplificado; hint e atributos pattern/placeholder/inputmode/title removidos |
| `app/views/tasks/edit.html.erb` | `text_field` → `time_field`; label simplificado; hint e atributos redundantes removidos |

### Testes

- `spec/requests/tasks_spec.rb` — 34 examples, 0 failures

### Decisões

- Nenhuma mudança no model ou controller necessária — `time_field` entrega `HH:MM` compatível com `hm_to_decimal` e `estimated_hours_hm_must_be_valid`
- `aria-describedby` apontava para `estimated-hours-hint` removido — atualizado para apontar apenas ao erro quando presente
