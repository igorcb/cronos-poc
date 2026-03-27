# Story 5.4: Implementar Totalizadores por Empresa no Mês

Status: ready-for-dev

## Story

**Como** Igor,
**Quero** ver total de horas e valor por empresa no mês,
**Para que** eu saiba quanto trabalhei para cada cliente.

## Acceptance Criteria

1. Método `TimeEntry.total_hours_by_company(month, year, user)` criado
2. Método usa `GROUP BY company_id` com `SUM(duration_minutes)`
3. Retorna hash: `{ company => { hours: X, value: Y } }`
4. Dashboard exibe tabela: empresa, horas totais, valor total
5. Cada linha mostra: company.name, total de horas formatado, R$ total
6. Query usa eager loading para evitar N+1
7. Carregamento < 1 segundo

## Dev Notes

```ruby
# app/models/time_entry.rb
def self.total_by_company(month, year, user)
  where(user: user)
    .where("EXTRACT(MONTH FROM date) = ? AND EXTRACT(YEAR FROM date) = ?", month, year)
    .includes(:company)
    .group(:company)
    .select("company_id, SUM(duration_minutes) as total_minutes, SUM(calculated_value) as total_value")
end
```
