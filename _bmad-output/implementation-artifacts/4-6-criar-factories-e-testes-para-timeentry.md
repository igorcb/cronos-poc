# Story 4.6: Criar Factories e Testes para TimeEntry

Status: ready-for-dev

## Story

**Como** desenvolvedor,
**Quero** testes completos para TimeEntry,
**Para que** cálculos e validações sejam garantidos.

## Acceptance Criteria

1. Factory possui associations: user, company, project
2. Factory possui: `date { Date.today }`, `start_time { '09:00' }`, `end_time { '17:00' }`
3. Testes confirmam validações de presence
4. Teste confirma validação: end_time > start_time
5. Teste confirma validação: project pertence a company
6. Teste confirma cálculo correto de duration_minutes
7. Teste confirma cálculo correto de calculated_value usando hourly_rate
8. `bundle exec rspec spec/models/time_entry_spec.rb` passa 100%

## Dev Notes

```ruby
# spec/factories/time_entries.rb
FactoryBot.define do
  factory :time_entry do
    association :user
    association :company
    association :project

    date { Date.today }
    start_time { Time.zone.parse('09:00') }
    end_time { Time.zone.parse('17:00') }
    activity { Faker::Lorem.sentence }
    status { 'pending' }

    before(:create) do |entry|
      entry.hourly_rate = entry.company.hourly_rate
      entry.project.company = entry.company unless entry.project.company_id == entry.company_id
    end
  end
end
```

```ruby
# spec/models/time_entry_spec.rb
require 'rails_helper'

RSpec.describe TimeEntry, type: :model do
  describe 'validations' do
    it { should validate_presence_of(:date) }
    it { should validate_presence_of(:start_time) }
    it { should validate_presence_of(:end_time) }
    it { should validate_inclusion_of(:status).in_array(%w[pending completed reopened delivered]) }

    describe 'end_time_after_start_time' do
      let(:entry) { build(:time_entry, start_time: '10:00', end_time: '09:00') }

      it 'adds error when end_time is before start_time' do
        entry.valid?
        expect(entry.errors[:end_time]).to include("deve ser posterior ao horário de início")
      end
    end
  end

  describe 'calculations' do
    let(:company) { create(:company, hourly_rate: 100.00) }
    let(:entry) { create(:time_entry, company: company, start_time: '09:00', end_time: '17:00') }

    it 'calculates duration_minutes correctly' do
      expect(entry.duration_minutes).to eq(480)
    end

    it 'calculates calculated_value correctly' do
      expect(entry.calculated_value).to eq(800.00)
    end
  end
end
```
