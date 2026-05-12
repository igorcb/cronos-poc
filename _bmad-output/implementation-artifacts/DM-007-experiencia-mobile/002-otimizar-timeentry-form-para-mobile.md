# Story 8.2: Otimizar TimeEntry Form para Mobile

Status: done

## Story

**Como** Igor,
**Quero** formulário de entrada rápido no mobile,
**Para que** registro continue sendo ~30 segundos.

## Acceptance Criteria

1. [x] Inputs de data/hora usam type correto: `type="date"`, `type="time"`
2. [x] Teclado mobile abre automaticamente com tipo correto
3. [x] Labels são claras e visíveis
4. [x] Textarea de activity tem altura adequada para touch
5. [x] Botão submit é destacado e grande o suficiente
6. [x] Validações client-side funcionam perfeitamente em mobile

## Dev Notes

```erb
<%= f.date_field :date, type: "date", class: "w-full min-h-[44px] text-lg" %>
<%= f.time_field :start_time, type: "time", class: "w-full min-h-[44px] text-lg" %>
<%= f.text_area :activity, rows: 4, class: "w-full min-h-[88px] text-base" %>
<%= f.submit "Salvar", class: "w-full sm:w-auto min-h-[44px] bg-blue-600 text-white px-8 py-3 text-lg rounded-lg" %>
```

## Tasks/Subtasks

- [x] AC1/AC2: Garantir `type="date"` no `date_field` + `inputmode="numeric"` para campo HH:MM
- [x] AC4: Textarea de notas com `min-h-[88px]` (dobro do touch target mínimo)
- [x] AC5: Botão submit com `w-full sm:w-auto`, `px-8 py-3`, `text-lg`, `font-semibold`, `rounded-lg`
- [x] AC6: Campo `estimated_hours_hm` com `pattern="\\d{1,2}:\\d{2}"` e `title` explicativo
- [x] Replicar todas as melhorias em `edit.html.erb`
- [x] Criar spec `spec/requests/mobile_timeentry_form_spec.rb` cobrindo todos os ACs
- [x] Atualizar spec `mobile_first_spec.rb` para refletir nova classe do submit
- [x] Suite completa: 468 examples, 0 failures

## File List

- `app/views/tasks/new.html.erb` — Melhorias mobile: inputmode, min-h-[88px], w-full submit, pattern
- `app/views/tasks/edit.html.erb` — Mesmas melhorias do new.html.erb
- `spec/requests/mobile_timeentry_form_spec.rb` — Novo spec cobrindo ACs 1-6 da Story 8.2
- `spec/requests/mobile_first_spec.rb` — Atualizado: matcher do submit mais flexível

## Change Log

- 2026-04-08: Implementação Story 8.2 — otimização mobile do formulário de Task (ACs 1-6 completos)

## Dev Agent Record

### Implementation Plan

A story focou em melhorias de UX mobile no formulário existente de Task. O modelo Task não possui campo `start_time` — o campo referenciado no Dev Notes é hipotético. As melhorias foram aplicadas nos campos reais existentes:

1. **AC1/AC2 (type correto + teclado mobile):** `date_field` já gera `type="date"`. Campo `estimated_hours_hm` recebeu `inputmode="numeric"` para abrir teclado numérico no mobile.

2. **AC4 (textarea altura):** Alterado de `min-h-[44px]` para `min-h-[88px]` — dobro do touch target mínimo, adequado para área de texto.

3. **AC5 (submit destacado):** Classe ampliada de `px-6 py-2 text-sm` para `w-full sm:w-auto px-8 py-3 text-lg font-semibold rounded-lg` — ocupa largura total no mobile, auto no desktop.

4. **AC6 (validações client-side):** Adicionado `pattern="\\d{1,2}:\\d{2}"` e `title` explicativo no campo HH:MM para validação nativa do browser sem JavaScript adicional.

### Completion Notes

- 22 novos specs cobrindo todos os 6 ACs da Story 8.2 — todos passando
- 1 spec existente (`mobile_first_spec.rb`) atualizado para refletir nova classe do submit
- Suite completa: 468 examples, 0 failures, 1 pending (pre-existente e esperado)
- Nenhuma dependência adicional necessária
- Implementação aplica-se a `new.html.erb` e `edit.html.erb`
