# Story 8.2: Otimizar TimeEntry Form para Mobile

Status: ready-for-dev

## Story

**Como** Igor,
**Quero** formulário de entrada rápido no mobile,
**Para que** registro continue sendo ~30 segundos.

## Acceptance Criteria

1. Inputs de data/hora usam type correto: `type="date"`, `type="time"`
2. Teclado mobile abre automaticamente com tipo correto
3. Labels são claras e visíveis
4. Textarea de activity tem altura adequada para touch
5. Botão submit é destacado e grande o suficiente
6. Validações client-side funcionam perfeitamente em mobile

## Dev Notes

```erb
<%= f.date_field :date, type: "date", class: "w-full min-h-[44px] text-lg" %>
<%= f.time_field :start_time, type: "time", class: "w-full min-h-[44px] text-lg" %>
<%= f.text_area :activity, rows: 4, class: "w-full min-h-[88px] text-base" %>
<%= f.submit "Salvar", class: "w-full sm:w-auto min-h-[44px] bg-blue-600 text-white px-8 py-3 text-lg rounded-lg" %>
```
