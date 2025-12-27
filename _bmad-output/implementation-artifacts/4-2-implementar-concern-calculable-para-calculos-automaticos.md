# Story 4.2: Implementar Concern Calculable para Cálculos Automáticos

Status: ready-for-dev

## Story

**Como** desenvolvedor,
**Quero** cálculos automáticos de duração e valor,
**Para que** não haja erros manuais.

## Acceptance Criteria

1. Concern possui `before_save :calculate_duration, :calculate_value`
2. Método `calculate_duration` calcula `(end_time - start_time) / 60` em minutos
3. Método `calculate_value` calcula `(duration_minutes / 60.0) * company.hourly_rate`
4. TimeEntry `include Calculable`
5. Ao salvar TimeEntry, campos duration_minutes e calculated_value são preenchidos automaticamente
6. Testes unitários confirmam cálculos precisos

## Dev Notes

### Concern Template

```ruby
# app/models/concerns/calculable.rb
module Calculable
  extend ActiveSupport::Concern

  included do
    before_save :calculate_duration
    before_save :calculate_value
  end

  def calculate_duration
    return unless start_time && end_time

    self.duration_minutes = ((end_time - start_time) / 60).to_i
  end

  def calculate_value
    return unless duration_minutes && company&.hourly_rate

    hours = duration_minutes / 60.0
    self.calculated_value = (hours * company.hourly_rate).round(2)
  end

  def formatted_duration
    hours = duration_minutes / 60
    minutes = duration_minutes % 60
    "#{hours}h#{minutes.to_s.rjust(2, '0')}m"
  end
end
```

### TimeEntry Update

```ruby
# app/models/time_entry.rb
class TimeEntry < ApplicationRecord
  include Calculable

  # ... restante do model
end
```

### Test Template

```ruby
describe Calculable do
  let(:company) { create(:company, hourly_rate: 100.00) }
  let(:entry) do
    build(:time_entry,
          company: company,
          start_time: Time.zone.parse('09:00'),
          end_time: Time.zone.parse('17:00'))
  end

  it 'calculates duration_minutes correctly' do
    entry.save
    expect(entry.duration_minutes).to eq(480) # 8 horas = 480 minutos
  end

  it 'calculates calculated_value correctly' do
    entry.save
    expect(entry.calculated_value).to eq(800.00) # 8h * R$100 = R$800
  end
end
```

## CRITICAL GUARDRAILS

- [ ] Cálculos devem ser 100% precisos (NFR10)
- [ ] Usar `round(2)` para valores monetários
- [ ] Testar edge cases (1 minuto, 23h59, etc)
- [ ] hourly_rate copiado de company.hourly_rate no momento do registro (ARQ24)

