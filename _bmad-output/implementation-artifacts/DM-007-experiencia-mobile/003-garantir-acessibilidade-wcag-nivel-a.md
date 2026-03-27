# Story 8.3: Garantir Acessibilidade WCAG Nível A

Status: ready-for-dev

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
