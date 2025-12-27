# Story 2.5: Criar Factory e Testes de Model para Company

Status: ready-for-dev

## Story

**Como** desenvolvedor,
**Quero** testes automatizados para o model Company,
**Para que** validações e comportamentos sejam garantidos.

## Acceptance Criteria

**Given** que RSpec está configurado

**When** crio factory para Company em spec/factories/companies.rb

**Then**
1. Factory possui: `name { Faker::Company.name }`, `hourly_rate { Faker::Number.decimal(l_digits: 2, r_digits: 2) }`
2. Testes de validação confirmam presence de name e hourly_rate
3. Teste confirma que scope `active` retorna apenas empresas ativas
4. Teste confirma que `deactivate!` muda active para false
5. Teste confirma que `activate!` muda active para true
6. `bundle exec rspec spec/models/company_spec.rb` passa 100%

## Tasks / Subtasks

- [ ] Criar factory (AC: #1)
  - [ ] Criar arquivo `spec/factories/companies.rb`
  - [ ] Definir factory com name e hourly_rate usando Faker
  - [ ] Garantir valores realistas (hourly_rate > 0)

- [ ] Criar spec de model (AC: #2-5)
  - [ ] Criar arquivo `spec/models/company_spec.rb`
  - [ ] Testes de validação: presence de name e hourly_rate
  - [ ] Teste de validação: hourly_rate > 0
  - [ ] Teste de scope active
  - [ ] Teste de método deactivate!
  - [ ] Teste de método activate!

- [ ] Executar testes (AC: #6)
  - [ ] `bundle exec rspec spec/models/company_spec.rb`
  - [ ] Confirmar todos passam
  - [ ] Corrigir falhas se houver

## Dev Notes

### Factory Template

```ruby
# spec/factories/companies.rb
FactoryBot.define do
  factory :company do
    name { Faker::Company.name }
    hourly_rate { Faker::Number.decimal(l_digits: 2, r_digits: 2) }
    active { true }

    trait :inactive do
      active { false }
    end
  end
end
```

### Spec Template

```ruby
# spec/models/company_spec.rb
require 'rails_helper'

RSpec.describe Company, type: :model do
  describe 'validations' do
    it { should validate_presence_of(:name) }
    it { should validate_presence_of(:hourly_rate) }
    it { should validate_numericality_of(:hourly_rate).is_greater_than(0) }
  end

  describe 'scopes' do
    let!(:active_company) { create(:company, active: true) }
    let!(:inactive_company) { create(:company, :inactive) }

    it 'returns only active companies' do
      expect(Company.active).to include(active_company)
      expect(Company.active).not_to include(inactive_company)
    end
  end

  describe '#deactivate!' do
    let(:company) { create(:company) }

    it 'sets active to false' do
      expect { company.deactivate! }.to change { company.active }.from(true).to(false)
    end
  end

  describe '#activate!' do
    let(:company) { create(:company, :inactive) }

    it 'sets active to true' do
      expect { company.activate! }.to change { company.active }.from(false).to(true)
    end
  end
end
```

### Comandos Úteis

```bash
# Executar todos os testes de Company
bundle exec rspec spec/models/company_spec.rb

# Executar teste específico
bundle exec rspec spec/models/company_spec.rb:10

# Executar com output detalhado
bundle exec rspec spec/models/company_spec.rb --format documentation
```

### References

- [Epics: Story 2.5](/home/igor/rails_app/cronos-poc/_bmad-output/planning-artifacts/epics.md#story-25-criar-factory-e-testes-de-model-para-company)

## Dev Agent Record

### Completion Notes List

_A ser preenchido pelo Dev Agent ao finalizar:_
- [ ] Factory criada
- [ ] Testes de validação implementados
- [ ] Testes de scopes implementados
- [ ] Testes de métodos implementados
- [ ] Todos os testes passam

### File List

_A ser preenchido pelo Dev Agent com arquivos criados/modificados_

---

## CRITICAL DEVELOPER GUARDRAILS

### ⚠️ VALIDAÇÕES OBRIGATÓRIAS

1. **ANTES de marcar story como concluída, VERIFICAR:**
   - [ ] `bundle exec rspec spec/models/company_spec.rb` passa 100%
   - [ ] Factory gera dados válidos
   - [ ] Testes cobrem validações, scopes e métodos

### 🎯 OBJETIVOS DESTA STORY

**Esta story DEVE entregar:**
- ✅ Factory funcional
- ✅ Testes de validação
- ✅ Testes de comportamento
- ✅ 100% de testes passando
