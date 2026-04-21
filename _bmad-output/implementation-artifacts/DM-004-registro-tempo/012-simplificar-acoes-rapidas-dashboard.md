# Story 4.12: Simplificar Ações Rápidas no Dashboard

**Status:** ready-for-dev
**Domínio:** DM-004-registro-tempo
**Data:** 2026-04-21
**Epic:** Epic 4 — Task Management System
**Story ID:** 4.12
**Story Key:** 4-12-simplificar-acoes-rapidas-dashboard

---

## Story

**Como** Igor (usuário do sistema),
**Quero** ver apenas o botão "Nova Tarefa" na seção de ações rápidas do dashboard,
**Para que** o dashboard seja focado na entrada de dados de tempo, sem distrações para Empresas e Projetos.

---

## Contexto Técnico

### Arquivo a modificar
- `app/views/dashboard/index.html.erb`

### Estado atual — seção "Ações Rápidas" (linhas 66-86)
```erb
<section aria-labelledby="quick-actions-heading">
  <div class="bg-gray-800 rounded-lg shadow-sm p-6 border border-gray-700">
    <h2 id="quick-actions-heading" class="text-lg font-semibold text-white mb-4">Ações Rápidas</h2>
    <div class="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-4">
      <%= link_to new_task_path, class: "block border border-gray-600 rounded-lg p-4 ...", aria: { label: "Nova Entrada - Registrar horas trabalhadas" } do %>
        <h3 ...>⏱️ Nova Entrada</h3>
        <p ...>Registrar horas trabalhadas</p>
      <% end %>

      <%= link_to companies_path, ... %>  <!-- REMOVER -->
      <%= link_to projects_path, ... %>   <!-- REMOVER -->
    </div>
  </div>
</section>
```

### Estado desejado
- Manter apenas o card de "Nova Tarefa" (`new_task_path`)
- Remover cards de Empresas e Projetos (acessíveis via navbar)
- Simplificar o layout: sem grid multi-coluna para 1 único botão
- Atualizar o aria-label de "Nova Entrada" para "Nova Tarefa"

---

## Acceptance Criteria

- [ ] AC1: Seção "Ações Rápidas" exibe apenas 1 botão: "Nova Tarefa"
- [ ] AC2: Cards de "Empresas" e "Projetos" removidos do dashboard
- [ ] AC3: Botão "Nova Tarefa" aponta para `new_task_path`
- [ ] AC4: Layout simplificado (não usa grid de 3 colunas para 1 item)
- [ ] AC5: Texto do botão atualizado de "Nova Entrada" para "Nova Tarefa"
- [ ] AC6: `aria-label` atualizado para "Nova Tarefa - Registrar nova tarefa"

---

## Dev Notes

### Substituição completa da seção Ações Rápidas

```erb
<!-- Ações Rápidas -->
<section aria-labelledby="quick-actions-heading">
  <div class="bg-gray-800 rounded-lg shadow-sm p-6 border border-gray-700">
    <h2 id="quick-actions-heading" class="text-lg font-semibold text-white mb-4">Ações Rápidas</h2>
    <%= link_to new_task_path,
        class: "inline-flex items-center gap-2 bg-blue-600 hover:bg-blue-700 text-white px-6 py-3 rounded-lg font-medium transition min-h-[44px]",
        aria: { label: "Nova Tarefa - Registrar nova tarefa" } do %>
      ⏱️ Nova Tarefa
    <% end %>
  </div>
</section>
```

### Rotas relevantes
- `new_task_path` → `GET /tasks/new`

---

## Guardrails

- **NÃO** remover a seção inteira — manter o card com o botão Nova Tarefa
- **NÃO** alterar as seções de stats (Horas Hoje, Horas Mês, Valor Mês)
- **NÃO** adicionar lógica de controller — apenas mudança de view

---

## Dev Agent Record

### Checklist de Implementação
- [ ] Cards Empresas e Projetos removidos
- [ ] Botão "Nova Tarefa" mantido e atualizado
- [ ] Layout simplificado (sem grid desnecessário)
- [ ] aria-label atualizado

### Notas de Implementação
_(Preencher pelo dev agent)_
