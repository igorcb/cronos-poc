# Story 6.4: Criar Stimulus Controller para Filtros com Turbo Frames

Status: done

## Story

**Como** Igor,
**Quero** que filtros funcionem sem reload de página,
**Para que** experiência seja fluida.

## Acceptance Criteria

1. Formulário de filtros está dentro de `<turbo-frame id="time_entries_list">` ✅
2. Ao mudar qualquer filtro, submit automático via Turbo Frame ✅
3. Apenas lista de entradas recarrega, header/sidebar permanecem ✅
4. URL atualiza com query params ✅ (via `data-turbo-action="advance"`)
5. Loading state é exibido durante fetch ✅ (via CSS `turbo-frame[busy]`)
6. Transição é suave (< 1 segundo, NFR4) ✅

## Dev Notes

```javascript
// app/javascript/controllers/filter_controller.js
import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  submit() {
    clearTimeout(this.timeout)
    this.timeout = setTimeout(() => {
      this.element.requestSubmit()
    }, 300)
  }
}
```

```erb
<turbo-frame id="time_entries_list">
  <%= form_with url: time_entries_path, method: :get, data: { controller: "filter", turbo_frame: "time_entries_list" } do |f| %>
    <%= f.select :company_id, Company.active.pluck(:name, :id), { include_blank: "Todas" },
        { data: { action: "change->filter#submit" } } %>
  <% end %>
</turbo-frame>
```

## Dev Agent Record

### Implementation

- `app/javascript/controllers/filter_controller.js` — Stimulus controller com debounce 300ms usando `requestSubmit()`
- `app/javascript/controllers/index.js` — Registrado `FilterController` como `"filter"`
- `app/views/tasks/index.html.erb` — Envolvido com `<turbo-frame id="time_entries_list" data-turbo-action="advance">`
- `app/views/tasks/_filters.html.erb` — Form atualizado com `data-controller="filter"`, `data-turbo-frame="time_entries_list"`, e `data-action="change->filter#submit"` em todos os inputs/selects
- `app/assets/stylesheets/application.tailwind.css` — CSS de loading state via `turbo-frame[busy]`
- `config/environments/test.rb` — `config.hosts = nil` para permitir request specs

### Tests Created

- `spec/requests/tasks_filter_turbo_frame_spec.rb` — 16 exemplos cobrindo AC1-AC4 e AC3 (DOM position)

### Decisions

- Formulário **dentro** do turbo-frame (AC1 literal) — o Turbo extrai o frame do response, mantendo header/sidebar intactos
- `data-turbo-action="advance"` no `turbo-frame` para atualizar a URL (AC4)
- Loading state via CSS puro (`turbo-frame[busy]`) — sem JS adicional
- `config.hosts = nil` em test env necessário pois o container roda com `RAILS_ENV=development` por padrão; request specs precisam do test env explícito

## Playwright UI Validation

Validado via Playwright MCP em http://localhost:3001 (igor@cronos-poc.local):

| AC | Resultado |
|---|---|
| AC1 — turbo-frame#time_entries_list envolve lista | ✅ |
| AC2 — submit automático ao mudar Status, Período, Empresa | ✅ |
| AC3 — navbar/header fora do frame, permanece intacto | ✅ |
| AC4 — URL atualiza com query params (ex: `?status=pending&period=last_7_days`) | ✅ |
| AC5 — loading state CSS via `turbo-frame[busy]` + `position:relative` | ✅ |
| AC6 — transição fluida (< 1s) | ✅ |

**Observação:** Bundle JS precisou ser recompilado (`rails javascript:build` + `assets:precompile`) após adicionar o `filter_controller` — o container usava o arquivo de 28/mar desatualizado.

## File List

- `app/javascript/controllers/filter_controller.js` (NEW)
- `app/javascript/controllers/index.js` (MODIFIED)
- `app/views/tasks/index.html.erb` (MODIFIED)
- `app/views/tasks/_filters.html.erb` (MODIFIED)
- `app/assets/stylesheets/application.tailwind.css` (MODIFIED)
- `config/environments/test.rb` (MODIFIED)
- `spec/requests/tasks_filter_turbo_frame_spec.rb` (NEW)
