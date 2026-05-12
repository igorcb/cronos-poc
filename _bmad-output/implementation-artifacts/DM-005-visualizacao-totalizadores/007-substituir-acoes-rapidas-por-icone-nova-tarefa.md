# Story 5.7: Substituir Seção "Ações Rápidas" por Ícone de Nova Tarefa

**Status:** done
**Domínio:** DM-005-visualizacao-totalizadores
**Data:** 2026-04-22
**Epic:** Epic 5 — Visualização & Dashboard
**Story ID:** 5.7
**Story Key:** 5-7-substituir-acoes-rapidas-por-icone-nova-tarefa

---

## Story

**Como** Igor (usuário do sistema),
**Quero** um ícone `+` discreto no lugar da seção "Ações Rápidas" do dashboard,
**Para que** o dashboard fique mais limpo e eu ainda consiga criar uma nova tarefa rapidamente.

---

## Contexto de Negócio

A seção "Ações Rápidas" com o botão textual "⏱️ Nova Tarefa" ocupa espaço desnecessário no dashboard. A substituição por um ícone `+` simples — com o mesmo estilo visual dos ícones dos cards de stats — mantém a ação acessível sem poluir a interface.

---

## Acceptance Criteria

**AC1 — Remover seção "Ações Rápidas":**
- A `<section>` com `aria-labelledby="quick-actions-heading"` e o botão "⏱️ Nova Tarefa" devem ser completamente removidos do `dashboard/index.html.erb`

**AC2 — Adicionar ícone `+` no lugar:**
- No espaço onde estava "Ações Rápidas", adicionar um link com ícone `+` SVG
- Estilo idêntico ao ícone dos cards de stats: `bg-blue-900 rounded-md p-3`
- Ícone SVG `+` com `h-6 w-6 text-blue-400`
- O elemento inteiro é clicável e navega para `new_task_path`
- `aria-label: "Nova Tarefa"` para acessibilidade

**AC3 — Posicionamento:**
- O ícone deve aparecer na mesma posição vertical onde estava a seção "Ações Rápidas" (entre os cards de stats e a lista "Tarefas do Mês")
- Alinhado à esquerda, sem card wrapper, sem título de seção

**AC4 — Sem texto:**
- Apenas o ícone — sem label "Nova Tarefa", sem texto, sem tooltip obrigatório

---

## Referência Visual

### Ícone dos cards de stats (referência de tamanho/estilo)
```erb
<div class="flex-shrink-0 bg-blue-900 rounded-md p-3">
  <svg class="h-6 w-6 text-blue-400" fill="none" stroke="currentColor" viewBox="0 0 24 24" aria-hidden="true">
    <!-- ícone do card -->
  </svg>
</div>
```

### Implementação esperada do ícone Nova Tarefa
```erb
<section aria-label="Ação rápida">
  <%= link_to new_task_path, aria: { label: "Nova Tarefa" } do %>
    <div class="flex-shrink-0 bg-blue-900 rounded-md p-3 inline-flex hover:bg-blue-800 transition">
      <svg class="h-6 w-6 text-blue-400" fill="none" stroke="currentColor" viewBox="0 0 24 24" aria-hidden="true">
        <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 4v16m8-8H4"/>
      </svg>
    </div>
  <% end %>
</section>
```

---

## Guardrails

- **NÃO** remover a seção "Tarefas do Mês" — apenas a seção "Ações Rápidas"
- **NÃO** adicionar texto ou tooltip visível — apenas `aria-label` para acessibilidade
- **NÃO** criar novo card wrapper (sem `bg-gray-800 rounded-lg p-6`) — ícone standalone
- **NÃO** alterar os cards de stats (Horas Hoje, Horas Mês, Valor Mês)
- Manter `min-h-[44px]` implícito via `p-3` + ícone `h-6 w-6` para acessibilidade touch

---

## Dev Agent Record

### Checklist de Implementação
- [x] Remover `<section aria-labelledby="quick-actions-heading">` completo do `dashboard/index.html.erb`
- [x] Adicionar ícone `+` link no lugar, com estilo `bg-blue-900 rounded-md p-3`
- [x] Verificar que `new_task_path` resolve corretamente
- [x] Spec: verificar que seção "Ações Rápidas" não existe mais no response
- [x] Spec: verificar que link para `new_task_path` existe com ícone `+`
- [x] Testes passando sem regressão

### Notas de Implementação
- Removida seção `<section aria-labelledby="quick-actions-heading">` com card wrapper `bg-gray-800 rounded-lg shadow-sm p-6`
- Adicionado `<section aria-label="Ação rápida">` com link standalone para `new_task_path`
- Ícone SVG `+` com path `M12 4v16m8-8H4`, classes `h-6 w-6 text-blue-400`, dentro de `div bg-blue-900 rounded-md p-3 inline-flex hover:bg-blue-800 transition`
- `aria-label="Nova Tarefa"` no link para acessibilidade
- Spec atualizado: `spec/requests/dashboard_quick_actions_spec.rb` — 13 exemplos, 0 falhas
- Sem regressões em `dashboard_tasks_month_spec.rb` — 21 exemplos, 0 falhas

### File List
- `app/views/dashboard/index.html.erb` — seção Ações Rápidas substituída por ícone `+`
- `spec/requests/dashboard_quick_actions_spec.rb` — specs atualizados para story 5.7

### Change Log
- 2026-04-23: Story 5.7 implementada — seção "Ações Rápidas" removida, ícone `+` adicionado com estilo `bg-blue-900 rounded-md p-3`, 13 specs passando
