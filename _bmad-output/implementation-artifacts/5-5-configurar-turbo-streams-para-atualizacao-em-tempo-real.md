# Story 5.5: Configurar Turbo Streams para Atualização em Tempo Real

Status: ready-for-dev

## Story

**Como** Igor,
**Quero** que totais atualizem automaticamente ao criar/editar entradas,
**Para que** eu sempre veja dados atualizados.

## Acceptance Criteria

1. `after_commit :broadcast_totals_update` configurado
2. Broadcast atualiza target `daily_totals`
3. Broadcast atualiza target `monthly_totals`
4. Ao criar nova entrada, totais atualizam sem refresh manual
5. Feedback visual é instantâneo (< 500ms, NFR5)

## Dev Notes

```ruby
# app/models/time_entry.rb
after_commit :broadcast_totals_update

private

def broadcast_totals_update
  broadcast_replace_to(
    "user_#{user_id}_totals",
    target: "daily_totals",
    partial: "time_entries/daily_totals",
    locals: { date: date, user: user }
  )

  broadcast_replace_to(
    "user_#{user_id}_totals",
    target: "monthly_totals",
    partial: "time_entries/monthly_totals",
    locals: { month: date.month, year: date.year, user: user }
  )
end
```
