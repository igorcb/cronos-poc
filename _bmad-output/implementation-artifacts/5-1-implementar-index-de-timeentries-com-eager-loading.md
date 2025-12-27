# Story 5.1: Implementar Index de TimeEntries com Eager Loading

Status: ready-for-dev

## Story

**Como** Igor,
**Quero** visualizar lista de entradas do mês atual,
**Para que** eu veja todos os registros rapidamente.

## Acceptance Criteria

1. Rota `GET /time_entries` exibe entradas do mês atual
2. Query usa `TimeEntry.includes(:company, :project).where(user: current_user, date: Date.current.all_month)`
3. Bullet não detecta N+1 queries
4. Lista exibe: date, start_time, end_time, duration (formatado), company.name, project.name, activity, status, calculated_value
5. Carregamento completo < 2 segundos (NFR3)
6. Ordenação: mais recentes primeiro

## Dev Notes

```ruby
# app/controllers/time_entries_controller.rb
def index
  @time_entries = TimeEntry
    .includes(:company, :project)
    .where(user: current_user, date: Date.current.all_month)
    .order(date: :desc, created_at: :desc)
end
```

## CRITICAL GUARDRAILS

- [ ] SEMPRE usar `includes(:company, :project)` para prevenir N+1 (ARQ36)
- [ ] Bullet deve estar configurado e não deve detectar N+1
- [ ] Carregamento < 2s (NFR3)
