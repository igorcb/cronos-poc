# Story 3.4: Criar Factory e Testes para Project

Status: ready-for-dev

## Story

**Como** desenvolvedor,
**Quero** testes automatizados para Project,
**Para que** relacionamentos e validações sejam garantidos.

## Acceptance Criteria

**Given** que RSpec está configurado

**When** crio factory para Project

**Then**
1. Factory possui: `association :company`, `name { Faker::App.name }`
2. Testes confirmam validação de presence: name, company_id
3. Teste confirma associação `belongs_to :company`
4. Teste confirma `dependent: :restrict_with_error` bloqueia deleção se houver time_entries
5. `bundle exec rspec spec/models/project_spec.rb` passa 100%

## Dev Notes

### Factory Template

```ruby
# spec/factories/projects.rb
FactoryBot.define do
  factory :project do
    association :company
    name { Faker::App.name }
  end
end
```

### Spec Template

```ruby
# spec/models/project_spec.rb
require 'rails_helper'

RSpec.describe Project, type: :model do
  describe 'validations' do
    it { should validate_presence_of(:name) }
    it { should validate_presence_of(:company_id) }
  end

  describe 'associations' do
    it { should belong_to(:company) }
    it { should have_many(:time_entries).dependent(:restrict_with_error) }
  end

  describe 'dependent restrict' do
    let(:project) { create(:project) }

    context 'when project has time_entries' do
      before { create(:time_entry, project: project) }

      it 'raises error on destroy' do
        expect { project.destroy! }.to raise_error(ActiveRecord::DeleteRestrictionError)
      end
    end

    context 'when project has no time_entries' do
      it 'destroys successfully' do
        expect { project.destroy }.to change(Project, :count).by(-1)
      end
    end
  end
end
```
