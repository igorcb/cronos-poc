# Story 4.6: Criar Factories e Testes para Task e TaskItem

Status: backlog

<!-- Note: Validation is optional. Run validate-create-story for quality check before dev-story. -->

## Story

**Como** desenvolvedor,
**Quero** testes completos para Task e TaskItem,
**Para que** cálculos, validações e status automáticos sejam garantidos.

## Acceptance Criteria

**Given** que RSpec está configurado

**When** crio factories para Task e TaskItem

**Then**
1. factory Task possui: association :company, association :project
2. factory Task possui: `name { Faker::Lorem.sentence }`, `start_date { Date.today }`
3. factory Task possui: `estimated_hours { Faker::Number.decimal(l_digits: 1, r_digits: 2) }`
4. factory TaskItem possui: association :task
5. factory TaskItem possui: `start_time { '09:00' }`, `end_time { '10:30' }`
6. testes confirmam validações de presence
7. testes confirmam validação: project pertence a company
8. testes confirmam cálculo correto de hours_worked em TaskItem
9. testes confirmam recálculo automático de Task status
10. testes confirmam Task não recalcula status quando 'delivered'
11. testes confirmam cálculo de total_hours e calculated_value
12. `bundle exec rspec spec/models/task_spec.rb` passa 100%
13. `bundle exec rspec spec/models/task_item_spec.rb` passa 100%

## Tasks / Subtasks

- [ ] Criar factory para Task
  - [ ] Criar arquivo `spec/factories/tasks.rb`
  - [ ] Definir factory `:task`
  - [ ] Adicionar `association :company`
  - [ ] Adicionar `association :project`
  - [ ] Adicionar `name { Faker::Lorem.sentence }`
  - [ ] Adicionar `start_date { Date.today }`
  - [ ] Adicionar `estimated_hours { Faker::Number.decimal(l_digits: 1, r_digits: 2) }`
  - [ ] Adicionar `status { 'pending' }`
  - [ ] Adicionar `notes { Faker::Lorem.paragraph }` (opcional)

- [ ] Criar factory para TaskItem
  - [ ] Criar arquivo `spec/factories/task_items.rb`
  - [ ] Definir factory `:task_item`
  - [ ] Adicionar `association :task`
  - [ ] Adicionar `start_time { '09:00' }`
  - [ ] Adicionar `end_time { '10:30' }`
  - [ ] Adicionar `status { 'pending' }`
  - [ ] Deixar `hours_worked` ser calculado automaticamente

- [ ] Escrever testes do model Task
  - [ ] Criar `spec/models/task_spec.rb`
  - [ ] Testar associações: belongs_to :company, belongs_to :project, has_many :task_items
  - [ ] Testar validação de presence de name
  - [ ] Testar validação de presence de company
  - [ ] Testar validação de presence de project
  - [ ] Testar validação de presence de start_date
  [ ] Testar validação de presence de estimated_hours
  - [ ] Testar validação de presence de status
  - [ ] Testar validação de inclusion de status
  - [ ] Testar validação numérica de estimated_hours (greater_than 0)
  - [ ] Testar validação customizada project_must_belong_to_company
  [ ] Testar enum status
  - [ ] Testar scopes: pending, completed, delivered, by_company, by_project

- [ ] Escrever testes de cálculos do model Task
  - [ ] Testar método `total_hours` soma task_items.hours_worked
  - [ ] Testar método `calculated_value` retorna company.hourly_rate * total_hours
  - [ ] Testar método `recalculate_status!`
  - [ ] Testar atualização de end_date quando status → completed
  [ ] Testar atualização de delivery_date quando status → delivered
  - [ ] Testar recálculo de validated_hours após save

- [ ] Escrever testes do model TaskItem
  - [ ] Criar `spec/models/task_item_spec.rb`
  - [ ] Testar associação: belongs_to :task
  - [ ] Testar validação de presence de task
  [ ] Testar validação de presence de start_time
  - [ ] Testar validação de presence de end_time
  [ ] Testar validação de presence de status
  [ ] Testar validação de inclusion de status
  [ ] Testar validação customizada end_time_after_start_time
  [ ] Testar validação customizada task_must_not_be_delivered
  - [ ] Testar enum status
  [ ] Testar scopes: pending, completed, by_task, recent_first

- [ ] Escrever testes de cálculos do model TaskItem
  [ ] Testar callback `calculate_hours_worked` calcula duração corretamente
  [ ] Testar callback `update_task_status` chama task.recalculate_status!
  [ ] Testar callback `update_task_status` chama após destroy
  [ ] Testar cálculo com diferentes horários (ex: 08:00-10:30 = 2.5h)
  [ ] Testar cálculo com horários que atravessam meio-dia (ex: 11:30-13:15)

- [ ] Escrever testes de integração Task + TaskItem
  - [ ] Testar criação de TaskItem atualiza status da Task
  - [ ] Testar Task com status 'delivered' não aceita novos TaskItems
  - [ ] Testar deleção de TaskItem atualiza status da Task
  [ ] Testar múltiplos TaskItems e status da Task
  [ ] Testar cálculo de validated_hours da Task

- [ ] Executar suite de testes
  - [ ] Executar `bundle exec rspec spec/models/task_spec.rb`
  - [ ] Executar `bundle exec rspec spec/models/task_item_spec.rb`
  - [ ] Verificar que 100% dos testes passam
  [ ] Verificar cobertura de código (deve ser > 95%)
