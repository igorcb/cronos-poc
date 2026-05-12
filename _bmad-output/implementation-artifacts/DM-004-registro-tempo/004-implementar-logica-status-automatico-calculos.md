# Story 4.3: Implementar Lógica de Status Automático e Cálculos

Status: done

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

- [x] Implementar métodos de cálculos no model Task
  - [x] Adicionar método `total_hours` que retorna `task_items.sum(:hours_worked)`
  - [x] Adicionar método `calculated_value` que retorna `company.hourly_rate * total_hours`
  - [x] Adicionar método `recalculate_status!` que verifica último TaskItem
  - [x] Implementar lógica: se último TaskItem completed → status = 'completed'
  - [x] Implementar lógica: se último TaskItem pending → status = 'pending'
  - [x] Implementar proteção: return if delivered? (não recalcula se delivered)

- [x] Implementar callbacks de datas no model Task
  - [x] Adicionar before_save :update_end_date, if: :status_changed_to_completed?
  - [x] Implementar método `status_changed_to_completed?` (private)
  - [x] Implementar método `update_end_date` (private) que define `self.end_date = Date.today`
  - [x] Adicionar before_save :update_delivery_date, if: :status_changed_to_delivered?
  - [x] Implementar método `status_changed_to_delivered?` (private)
  - [x] Implementar método `update_delivery_date` (private) que define `self.delivery_date = Date.today`

- [x] Implementar callback de recálculo no model Task
  - [x] Adicionar after_save :recalculate_validated_hours
  - [x] Implementar método `recalculate_validated_hours` (private)
  - [x] Usar `update_column(:validated_hours, total_hours)` para evitar loops

- [x] Implementar método de cálculo no model TaskItem
  - [x] Implementar método `calculate_hours_worked` (private)
  - [x] Calcular duração: `(end_time - start_time) / 3600.0`
  - [x] Arredondar para 2 casas decimais: `.round(2)`
  - [x] Atribuir a `self.hours_worked`

- [x] Implementar callback de atualização de status no model TaskItem
  - [x] Implementar método `update_task_status` (private)
  - [x] Chamar `task.recalculate_status!` após save
  - [x] Chamar `task.recalculate_status!` após destroy

- [x] Escrever testes
  - [x] Testar recálculo de status quando TaskItem criado
  - [x] Testar recálculo de status quando TaskItem atualizado para completed
  - [x] Testar que Task delivered não recalcula status
  - [x] Testar cálculo de hours_worked
  - [x] Testar cálculo de total_hours
  - [x] Testar cálculo de calculated_value
  - [x] Testar atualização de end_date
  - [x] Testar atualização de delivery_date
