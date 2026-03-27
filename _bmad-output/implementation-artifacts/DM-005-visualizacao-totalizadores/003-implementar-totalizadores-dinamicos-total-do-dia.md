# Story 5.3: Implementar Totalizadores Dinâmicos (Total do Dia)

Status: ready-for-dev

## Story

**Como** Igor,
**Quero** ver total de horas trabalhadas no dia atual,
**Para que** eu acompanhe meu progresso diário.

## Acceptance Criteria

1. Método de classe `TimeEntry.total_hours_for_day(date, user)` criado
2. Método usa `SUM(EXTRACT(EPOCH FROM (end_time - start_time)) / 3600)`
3. Retorna total de horas em decimal
4. Dashboard exibe: "Total do dia: X.Xh"
5. Total atualiza automaticamente após criar nova entrada via Turbo Stream
6. Cálculo é instantâneo (< 500ms)

## Dev Notes

```ruby
# app/models/time_entry.rb
class TimeEntry < ApplicationRecord
  def self.total_hours_for_day(date, user)
    where(user: user, date: date)
      .sum("EXTRACT(EPOCH FROM (end_time - start_time)) / 3600")
  end
end
```
