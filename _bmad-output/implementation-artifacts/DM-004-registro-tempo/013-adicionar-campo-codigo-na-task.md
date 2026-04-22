# Story 4.13: Adicionar Campo Código na Task

**Status:** ready-for-dev
**Domínio:** DM-004-registro-tempo
**Data:** 2026-04-22
**Epic:** Epic 4 — Task Management System
**Story ID:** 4.13
**Story Key:** 4-13-adicionar-campo-codigo-na-task

---

## Story

**Como** Igor (usuário do sistema),
**Quero** registrar um código numérico opcional em cada tarefa e vê-lo exibido junto ao nome,
**Para que** eu possa identificar tarefas pelo código do card externo (ex: Trello, Jira) sem depender apenas do nome.

---

## Contexto de Negócio

Igor trabalha com cards de ferramentas externas como Trello (#14335) e precisa rastrear qual card corresponde a qual tarefa no Cronos. O campo código é opcional, numérico, inserido manualmente. Duas tarefas com mesmo código mas nomes diferentes são permitidas — apenas a combinação código+nome duplicada deve ser bloqueada.

---

## Acceptance Criteria

**AC1 — Migration:** campo `code` adicionado à tabela `tasks`
- Tipo: `string` (numérico mas armazenado como string para preservar zeros à esquerda)
- Nullable: `true` (campo opcional)
- Index: não necessário

**AC2 — Validação backend (model Task):**
- `code` aceita apenas dígitos (validação: `format: { with: /\A\d+\z/ }` quando presente)
- Unicidade da combinação `[code, name]` — `validates :code, uniqueness: { scope: :name }` quando presente
- Se `code` for blank, não aplicar validação de formato nem unicidade

**AC3 — Formulários (new e edit):**
- Campo `code` adicionado antes do campo `name`
- Label: "Código"
- Placeholder: "Ex: 14335"
- Input text com `inputmode: "numeric"` e `pattern: "[0-9]*"` para teclado numérico em mobile
- Não obrigatório (sem asterisco)
- Exibir erro de validação inline quando formato inválido ou duplicata código+nome

**AC4 — Exibição nas listagens:**
- Em todas as listagens de tasks (tasks/index, dashboard), a coluna "Tarefa" exibe:
  - Com código: `"14335 - Fix Agreement Cancellation"`
  - Sem código: `"Fix Agreement Cancellation"` (apenas o nome, sem traço)
- Helper ou método no model: `task.display_name` → retorna `"#{code} - #{name}"` ou `name`

**AC5 — Exibição no edit/show:**
- Campo `code` pré-populado com valor existente ao editar

**AC6 — Testes:**
- Model spec: validação de formato numérico, unicidade código+nome, campo opcional
- Request spec ou controller spec: create com código válido, create com código inválido, create com duplicata código+nome

---

## Guardrails

- **NÃO** tornar `code` obrigatório — é campo opcional
- **NÃO** usar `integer` no banco — usar `string` para preservar zeros à esquerda (ex: `007`)
- **NÃO** validar unicidade global de `code` — apenas a combinação `[code, name]`
- **NÃO** alterar a lógica de status, task_items ou cálculos existentes
- **NÃO** modificar `tasks/new.html.erb` e `tasks/edit.html.erb` sem verificar que são views inline (não usam `_form` partial — conforme memória do projeto)
- Manter padrão dark theme Tailwind: `bg-gray-700 border-gray-600 text-white`

---

## Contexto Técnico

### Schema atual de `tasks`
```ruby
create_table "tasks" do |t|
  t.bigint "company_id", null: false
  t.bigint "project_id", null: false
  t.string "name", null: false
  t.string "status", default: "pending", null: false
  t.date "start_date", null: false
  t.decimal "estimated_hours", precision: 10, scale: 2, null: false
  t.decimal "validated_hours", precision: 10, scale: 2
  t.date "end_date"
  t.date "delivery_date"
  t.text "notes"
  t.datetime "created_at", null: false
  t.datetime "updated_at", null: false
end
```

### Migration a criar
```ruby
add_column :tasks, :code, :string
```

### Model Task — validações a adicionar
```ruby
validates :code,
  format: { with: /\A\d+\z/, message: "deve conter apenas números" },
  uniqueness: { scope: :name, message: "já existe uma tarefa com este código e nome" },
  allow_blank: true
```

### Helper `display_name`
```ruby
# app/models/task.rb
def display_name
  code.present? ? "#{code} - #{name}" : name
end
```

### Views a modificar
- `app/views/tasks/new.html.erb` — adicionar campo `code` antes de `name`
- `app/views/tasks/edit.html.erb` — adicionar campo `code` antes de `name`
- `app/views/tasks/index.html.erb` — substituir `task.name` por `task.display_name`
- `app/views/dashboard/index.html.erb` — substituir `task.name` por `task.display_name`

### Strong params a atualizar
```ruby
# app/controllers/tasks_controller.rb
def task_params
  params.require(:task).permit(:code, :name, :company_id, :project_id,
                                :start_date, :estimated_hours, :status,
                                :end_date, :delivery_date, :notes)
end
```

---

## Dev Agent Record

### Checklist de Implementação
- [ ] Migration: `add_column :tasks, :code, :string`
- [ ] Model: validação de formato numérico e unicidade `[code, name]`
- [ ] Model: método `display_name`
- [ ] Strong params: incluir `code`
- [ ] `tasks/new.html.erb`: campo `code` adicionado
- [ ] `tasks/edit.html.erb`: campo `code` adicionado
- [ ] `tasks/index.html.erb`: exibe `task.display_name`
- [ ] `dashboard/index.html.erb`: exibe `task.display_name`
- [ ] Specs: model + request/controller
- [ ] Testes passando sem regressão

### Notas de Implementação
_(Preencher pelo dev agent)_
