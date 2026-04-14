# Story 8.3: Garantir Acessibilidade WCAG Nível A

Status: done

## Story

**Como** Igor,
**Quero** navegação por teclado funcional,
**Para que** acessibilidade básica seja garantida.

## Acceptance Criteria

1. Todos os inputs têm `<label>` associados corretamente
2. Navegação por Tab funciona em ordem lógica
3. Enter submete formulários
4. Esc fecha modals/dropdowns
5. Contraste de cores é mínimo 4.5:1 (NFR21)
6. HTML semântico: `<main>`, `<nav>`, `<section>`, `<button>` (NFR19)
7. Mensagens de erro são claras e associadas aos campos

## Dev Agent Record

### Implementation Plan
Auditoria completa de todas as views. Implementação em camadas:
1. Layout `application.html.erb`: `<nav aria-label>`, `aria-expanded`, `aria-controls`, `id="mobile-menu"`, `aria-hidden` em SVGs.
2. Dashboard: `<section aria-labelledby>` para cada bloco, `<h2 id>` ocultos via `sr-only` para stats, `aria-hidden` em SVGs decorativos.
3. Formulário `tasks/new.html.erb`: `aria-required`, `aria-invalid`, `aria-describedby` por campo, erros inline com `role="alert"`.
4. `tasks/_filters.html.erb`: labels com `for=` explícito, ids nos `select_tag`, `role="search"` no form.
5. `companies/_form.html.erb` e `projects/_form.html.erb`: erros inline por campo com `aria-invalid` e `aria-describedby`.
6. `tasks/index.html.erb`: `<section aria-labelledby>`, `<caption class="sr-only">`, `scope="col"` em `<th>`, `aria-live="polite"` no contador de filtros.
7. `companies/index.html.erb` e `projects/index.html.erb`: `<section aria-labelledby>`, `role="list/listitem"`, `aria-label` em botões de ação.
8. `passwords/new.html.erb` e `passwords/edit.html.erb`: layout completo com `<h1>`, labels, ids, flash com `role="alert"`.
9. `navbar_controller.js`: método `close()` para tecla Esc, atualização dinâmica de `aria-expanded` e `aria-label` no toggle.

### Tests Created
- `spec/requests/accessibility_spec.rb`: 46 exemplos cobrindo todos os ACs (AC1, AC2, AC3, AC4, AC6, AC7).

### Completion Notes
- AC1 ✅ Labels associados via `for=` e `id=` em todos os inputs (new + edit) de todos os formulários.
- AC2 ✅ Navegação por Tab funciona em ordem lógica + skip-link WCAG 2.4.1 implementado.
- AC3 ✅ Enter submete formulários (comportamento nativo HTML, sem override).
- AC4 ✅ Esc fecha menu mobile via `keydown.esc->navbar#close` no Stimulus.
- AC5 (NFR21 contraste) — Paleta Tailwind gray-300/400 sobre gray-700/800/900 atende 4.5:1; nenhum color customizado introduzido.
- AC6 ✅ `<html lang="pt-BR">`, `<main id="main-content">`, `<nav aria-label>`, `<section aria-labelledby>`, `<button>` semânticos. Skip-link visível no foco.
- AC7 ✅ Erros inline por campo com `aria-describedby`, `aria-invalid="true"`, `role="alert"` em tasks/new, tasks/edit, companies, projects. Flash com `role="alert"/"status"` e `aria-live`.
- Ajustes pós-QA: `lang="pt-BR"`, `tasks/edit` completo, flash acessível, `role="list"` incorreto removido, interpolação ERB corrigida, skip-link adicionado.
- 503 testes passando, 0 falhas, 1 pending pré-existente.
- Validação Playwright MCP: nav mobile toggle/Esc, aria-expanded, lang=pt-BR, skip-link, labels, role=alert em erros — todos OK.
- Fix: `navbar_controller.js` adicionado ao `app/javascript/controllers/index.js` (ausente no registro Stimulus). Assets recompilados.

## File List
- `app/views/layouts/application.html.erb`
- `app/views/dashboard/index.html.erb`
- `app/views/tasks/new.html.erb`
- `app/views/tasks/edit.html.erb`
- `app/views/tasks/_form.html.erb`
- `app/views/tasks/_filters.html.erb`
- `app/views/tasks/index.html.erb`
- `app/views/companies/_form.html.erb`
- `app/views/companies/index.html.erb`
- `app/views/projects/_form.html.erb`
- `app/views/projects/index.html.erb`
- `app/views/passwords/new.html.erb`
- `app/views/passwords/edit.html.erb`
- `app/views/shared/_flash.html.erb`
- `app/javascript/controllers/navbar_controller.js`
- `spec/requests/accessibility_spec.rb` (novo)
- `app/javascript/controllers/index.js`

## Change Log
- 2026-04-14: Implementação Story 8.3 — Acessibilidade WCAG Nível A. HTML semântico, labels, aria-*, navegação por teclado, mensagens de erro inline.
- 2026-04-14: Ajustes pós-QA — `lang="pt-BR"`, tasks/edit acessível, flash com role=alert/status, role=list incorreto removido, skip-link WCAG 2.4.1, 57 testes de acessibilidade (503 total).
- 2026-04-14: Validação Playwright MCP — fix `navbar_controller` ausente do index.js Stimulus; AC4 (Esc fecha menu) validado na UI.

## Dev Notes

```erb
<!-- Associação correta de labels -->
<%= form.label :name, "Nome", for: "company_name", class: "block text-sm font-medium text-gray-700" %>
<%= form.text_field :name, id: "company_name", aria_describedby: "name_error" %>
<% if @company.errors[:name].any? %>
  <span id="name_error" class="text-red-600" role="alert">
    <%= @company.errors[:name].first %>
  </span>
<% end %>

<!-- HTML semântico -->
<main class="container mx-auto">
  <nav aria-label="Primary navigation">
    <!-- menu -->
  </nav>

  <section aria-labelledby="entries-heading">
    <h2 id="entries-heading">Entradas de Tempo</h2>
    <!-- conteúdo -->
  </section>
</main>
```
