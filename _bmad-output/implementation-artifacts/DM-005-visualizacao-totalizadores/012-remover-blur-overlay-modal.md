# Story 5.12: Remover Blur do Overlay dos Modais

**Status:** done
**Domínio:** DM-005-visualizacao-totalizadores
**Data:** 2026-04-26
**Epic:** Epic 5 — Visualização & Dashboard
**Story ID:** 5.12
**Story Key:** 5-12-remover-blur-overlay-modal

---

## Contexto

Os modais do dashboard (Nova Tarefa e Computar Horas) usam `backdrop-blur-sm` no overlay, o que borra completamente a tela de trás. O usuário não consegue ver o conteúdo do dashboard enquanto o modal está aberto, o que dificulta o contexto visual.

A solução é remover o blur mantendo apenas o escurecimento (`bg-black/80`), permitindo que a tela de trás fique visível porém escurecida.

---

## História do Usuário

**Como** usuário do Cronos POC,
**Quero** que ao abrir um modal eu consiga ver (com escurecimento) o conteúdo do dashboard por trás,
**Para** manter o contexto visual de onde estou enquanto preencho o formulário.

---

## Critérios de Aceite

- [x] **AC1:** O overlay dos modais remove a classe `backdrop-blur-sm` — a tela de trás fica visível, apenas escurecida
- [x] **AC2:** O escurecimento (`bg-black/80`) é mantido para dar foco ao modal
- [x] **AC3:** A mudança se aplica a ambos os modais: **Nova Tarefa** (`tasks/new.html.erb`) e **Computar Horas** (`task_items/_modal_form.html.erb`)
- [x] **AC4:** Comportamento de fechar (Escape / clique no overlay) permanece inalterado

---

## Análise Técnica

### Arquivos a modificar

**`app/views/tasks/new.html.erb`** — linha com overlay:
```erb
<%# antes %>
<div class="fixed inset-0 z-50 flex items-center justify-center bg-black/80 backdrop-blur-sm overflow-y-auto"

<%# depois %>
<div class="fixed inset-0 z-50 flex items-center justify-center bg-black/80 overflow-y-auto"
```

**`app/views/task_items/_modal_form.html.erb`** — linha com overlay:
```erb
<%# antes %>
<div class="fixed inset-0 z-50 flex items-center justify-center bg-black/80 backdrop-blur-sm"

<%# depois %>
<div class="fixed inset-0 z-50 flex items-center justify-center bg-black/80"
```

---

## Arquivos a Modificar

| Arquivo | Ação |
|---------|------|
| `app/views/tasks/new.html.erb` | Remover `backdrop-blur-sm` do div do overlay |
| `app/views/task_items/_modal_form.html.erb` | Remover `backdrop-blur-sm` do div do overlay |

---

## Testes

- [x] Verificar visualmente que a tela de trás aparece escurecida mas sem blur ao abrir cada modal
- [x] Confirmar que fechar com Escape e clique no overlay ainda funciona

---

## Estimativa

**0,5 story points** (~30min) — remoção cirúrgica de uma classe CSS em 2 arquivos.

---

## File List

| Arquivo | Ação |
|---------|------|
| `app/views/tasks/new.html.erb` | Modificado — removido `backdrop-blur-sm` |
| `app/views/task_items/_modal_form.html.erb` | Modificado — removido `backdrop-blur-sm` |

---

## Dev Agent Record

### Implementation Notes

- Removido `backdrop-blur-sm` de `app/views/tasks/new.html.erb` (overlay usa `bg-black/50`)
- Removido `backdrop-blur-sm` de `app/views/task_items/_modal_form.html.erb` (overlay usa `bg-black/80`)
- Nota: `tasks/new.html.erb` usa `bg-black/50` (não `/80` como na story) — mantido como estava, pois a story apenas pede remoção do blur
- Nenhum spec verificava `backdrop-blur-sm`; specs existentes continuam passando (40 + 36 = 76 exemplos, 0 falhas)

### Completion Notes

✅ AC1 — `backdrop-blur-sm` removido dos dois modais
✅ AC2 — Escurecimento (`bg-black/50` e `bg-black/80`) mantido
✅ AC3 — Ambos os modais alterados: Nova Tarefa e Computar Horas
✅ AC4 — `data-action` com `modal#closeOnOverlayClick` e `keydown.escape@window->modal#close` intocados

### Change Log

- 2026-05-04: Removido `backdrop-blur-sm` dos overlays dos modais Nova Tarefa e Computar Horas
