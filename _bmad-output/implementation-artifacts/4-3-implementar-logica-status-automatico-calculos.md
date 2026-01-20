# Story 4.3: Implementar Lógica de Status Automático e Cálculos

Status: backlog

<!-- Note: Validation is optional. Run validate-create-story for quality check before dev-story. -->

## Story

**Como** desenvolvedor,
**Quero** que Task status atualize automaticamente baseado em TaskItems,
**Para que** usuário não precise gerenciar status manualmente.

## Acceptance Criteria

**Given** que models Task e TaskItem existem

**When** implemento lógica de status automático

**Then**
1. Task possui método `recalculate_status!` que verifica último TaskItem criado
2. se último TaskItem criado está 'completed', Task status = 'completed'
3. se último TaskItem criado está 'pending', Task status = 'pending'
4. Task com status 'delivered' NÃO recalcula status (read-only)
5. Task possui before_save :update_end_date quando status → 'completed'
6. Task possui before_save :update_delivery_date quando status → 'delivered'
7. Task possui after_save :recalculate_validated_hours
8. Task possui método `total_hours` que soma task_items.hours_worked
9. Task possui método `calculated_value` que calcula company.hourly_rate * total_hours
10. TaskItem callback `calculate_hours_worked` calcula (end_time - start_time) / 3600.0
11. TaskItem callback `update_task_status` chama task.recalculate_status!
12. testes confirmam status atualiza corretamente

## Tasks / Subtasks

- [ ] Implementar métodos de cálculos no model Task
  - [ ] Adicionar método `total_hours` que retorna `task_items.sum(:hours_worked)`
  - [ ] Adicionar método `calculated_value` que retorna `company.hourly_rate * total_hours`
  - [ ] Adicionar método `recalculate_status!` que verifica último TaskItem
  - [ ] Implementar lógica: se último TaskItem completed → status = 'completed'
  - [ ] Implementar lógica: se último TaskItem pending → status = 'pending'
  - [ ] Implementar proteção: return if delivered? (não recalcula se delivered)

- [ ] Implementar callbacks de datas no model Task
  - [ ] Adicionar before_save :update_end_date, if: :status_changed_to_completed?
  - [ ] Implementar método `status_changed_to_completed?` (private)
  - [ ] Implementar método `update_end_date` (private) que define `self.end_date = Date.today`
  - [ ] Adicionar before_save :update_delivery_date, if: :status_changed_to_delivered?
  - [ ] Implementar método `status_changed_to_delivered?` (private)
  - [ ] Implementar método `update_delivery_date` (private) que define `self.delivery_date = Date.today`

- [ ] Implementar callback de recálculo no model Task
  - [ ] Adicionar after_save :recalculate_validated_hours
  - [ ] Implementar método `recalculate_validated_hours` (private)
  - [ ] Usar `update_column(:validated_hours, total_hours)` para evitar loops

- [ ] Implementar método de cálculo no model TaskItem
  - [ ] Implementar método `calculate_hours_worked` (private)
  - [ ] Calcular duração: `(end_time - start_time) / 3600.0`
  - [ ] Arredondar para 2 casas decimais: `.round(2)`
  - [ ] Atribuir a `self.hours_worked`

- [ ] Implementar callback de atualização de status no model TaskItem
  - [ ] Implementar método `update_task_status` (private)
  - [ ] Chamar `task.recalculate_status!` após save
  - [ ] Chamar `task.recalculate_status!` após destroy

- [ ] Escrever testes
  - [ ] Testar recálculo de status quando TaskItem criado
  - [ ] Testar recálculo de status quando TaskItem atualizado para completed
  - [ ] Testar que Task delivered não recalcula status
  - [ ] Testar cálculo de hours_worked
  - [ ] Testar cálculo de total_hours
  - [ ] Testar cálculo de calculated_value
  - [ ] Testar atualização de end_date
  - [ ] Testar atualização de delivery_date
