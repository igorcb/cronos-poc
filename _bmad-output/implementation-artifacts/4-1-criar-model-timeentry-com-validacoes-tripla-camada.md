# Story 4.1: Criar Model TimeEntry com Validações Tripla Camada

Status: ready-for-dev

## Story

**Como** desenvolvedor,
**Quero** criar tabela time_entries com validações robustas,
**Para que** dados sejam 100% confiáveis.

## Acceptance Criteria

1. Migration usa `create_table :time_entries, if_not_exists: true`
2. Possui `t.references :user, :company, :project, null: false, foreign_key: true, if_not_exists: true`
3. Possui `t.date :date, null: false`
4. Possui `t.time :start_time, :end_time, null: false`
5. Possui `t.text :activity, null: false`
6. Possui `t.string :status, null: false, default: 'pending'`
7. Possui `t.decimal :hourly_rate, :calculated_value, precision: 10, scale: 2, null: false`
8. Possui `t.integer :duration_minutes`
9. Check constraint criado: `end_time > start_time`
10. Índices compostos: `[user_id, date]`, `[company_id, date]`, `status`

## Dev Notes

### Migration Template

```ruby
class CreateTimeEntries < ActiveRecord::Migration[8.1]
  def change
    create_table :time_entries, if_not_exists: true do |t|
      t.references :user, null: false, foreign_key: true, if_not_exists: true
      t.references :company, null: false, foreign_key: true, if_not_exists: true
      t.references :project, null: false, foreign_key: true, if_not_exists: true
      t.date :date, null: false
      t.time :start_time, null: false
      t.time :end_time, null: false
      t.text :activity, null: false
      t.string :status, null: false, default: 'pending'
      t.decimal :hourly_rate, precision: 10, scale: 2, null: false
      t.decimal :calculated_value, precision: 10, scale: 2
      t.integer :duration_minutes

      t.timestamps
    end

    add_index :time_entries, [:user_id, :date], if_not_exists: true
    add_index :time_entries, [:company_id, :date], if_not_exists: true
    add_index :time_entries, :status, if_not_exists: true

    execute <<-SQL
      ALTER TABLE time_entries
      ADD CONSTRAINT check_end_after_start
      CHECK (end_time > start_time);
    SQL
  end
end
```

### Model Template

```ruby
# app/models/time_entry.rb
class TimeEntry < ApplicationRecord
  belongs_to :user
  belongs_to :company
  belongs_to :project

  validates :date, :start_time, :end_time, :activity, :status, presence: true
  validates :status, inclusion: { in: %w[pending completed reopened delivered] }

  validate :end_time_after_start_time
  validate :project_belongs_to_company

  private

  def end_time_after_start_time
    return if end_time.blank? || start_time.blank?
    errors.add(:end_time, "deve ser posterior ao horário de início") if end_time <= start_time
  end

  def project_belongs_to_company
    return if project.blank? || company.blank?
    errors.add(:project, "não pertence à empresa selecionada") if project.company_id != company_id
  end
end
```

## CRITICAL GUARDRAILS

- [ ] SEMPRE usar `if_not_exists: true` (ARQ18)
- [ ] SEMPRE decimal para dinheiro, NUNCA Float (ARQ25)
- [ ] Check constraint garante end_time > start_time (DB Layer)
- [ ] Model validation garante end_time > start_time (App Layer)
- [ ] Project pertence à Company selecionada

