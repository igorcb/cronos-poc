# Story 8.1: Implementar Mobile-First com Tailwind Breakpoints

Status: ready-for-dev

## Story

**Como** Igor,
**Quero** interface otimizada para mobile,
**Para que** eu possa registrar horas pelo celular.

## Acceptance Criteria

1. Formulários usam classes Tailwind: `sm:`, `md:`, `lg:`
2. Breakpoints: mobile < 768px, tablet 768-1023px, desktop ≥ 1024px
3. Forms em mobile ocupam largura completa
4. Forms em desktop têm max-width e centralização
5. Botões em mobile são touch-friendly (min-height: 44px)
6. Dropdowns em mobile são otimizados para touch

## Dev Notes

```erb
<!-- Mobile-first form layout -->
<div class="w-full sm:max-w-lg sm:mx-auto p-4 sm:p-6">
  <%= form_with model: @time_entry, class: "space-y-4" do |f| %>
    <div class="grid grid-cols-1 sm:grid-cols-2 gap-4">
      <%= f.date_field :date, class: "w-full min-h-[44px] rounded-md" %>
      <%= f.time_field :start_time, class: "w-full min-h-[44px] rounded-md" %>
    </div>
  <% end %>
</div>
```
