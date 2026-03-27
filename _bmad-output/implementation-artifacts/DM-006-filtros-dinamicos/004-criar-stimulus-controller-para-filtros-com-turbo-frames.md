# Story 6.4: Criar Stimulus Controller para Filtros com Turbo Frames

Status: ready-for-dev

## Story

**Como** Igor,
**Quero** que filtros funcionem sem reload de página,
**Para que** experiência seja fluida.

## Acceptance Criteria

1. Formulário de filtros está dentro de `<turbo-frame id="time_entries_list">`
2. Ao mudar qualquer filtro, submit automático via Turbo Frame
3. Apenas lista de entradas recarrega, header/sidebar permanecem
4. URL atualiza com query params
5. Loading state é exibido durante fetch
6. Transição é suave (< 1 segundo, NFR4)

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
