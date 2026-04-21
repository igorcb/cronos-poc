# Story 7.3: Criar Testes de System para Fluxo Completo de Tasks

**Status:** done
**Domínio:** DM-004-registro-tempo
**Data:** 2026-04-21
**Epic:** Epic 7 — Edição & Correção de Entradas
**Story ID:** 7.3
**Story Key:** 7-3-criar-testes-de-system-para-fluxo-completo

---

## Story

**Como** desenvolvedor,
**Quero** testes de system (Capybara) cobrindo o fluxo completo de CRUD de Tasks,
**Para que** regressões sejam detectadas automaticamente ao alterar views e controllers.

---

## Contexto Técnico Crítico

### Modelos existentes (NUNCA usar TimeEntry — não existe)
- `Task` — model principal com `name`, `company_id`, `project_id`, `start_date`, `estimated_hours_hm`, `status`
- `TaskItem` — itens de tarefa
- `Company`, `Project` — associações

### Infraestrutura de testes já configurada
- **Capybara** + **selenium-webdriver** disponíveis no Gemfile
- `spec/rails_helper.rb` já configura:
  - `driven_by :rack_test` para testes sem JS (default)
  - `driven_by :selenium_chrome_headless` para testes com `js: true`
- **FactoryBot** com factories: `:task`, `:company`, `:project`, `:user`

### Factory de User — senha é "Password123!"
```ruby
factory :user do
  email { Faker::Internet.unique.email }
  password { "Password123!" }
  password_confirmation { "Password123!" }
end
```

### Factory de Task
```ruby
create(:task)  # cria task com company e project associados automaticamente
create(:task, start_date: Date.current)  # aparece na listagem (filtro mês atual)
create(:task, company: company, project: project)  # associações explícitas
```

### Autenticação — campos do formulário de login
```ruby
visit new_session_path  # rota de login Rails 8
fill_in "Email", with: user.email_address  # campo :email_address (não :email)
fill_in "Password", with: "Password123!"
click_button "Entrar"
```

### URLs relevantes
```
GET  /tasks          → index com listagem, filtros, totalizadores
GET  /tasks/new      → formulário de criação
GET  /tasks/:id/edit → formulário de edição (navega fora do turbo-frame)
```

### Comportamento Turbo importante
- A listagem está dentro de `<turbo-frame id="time_entries_list">`
- Link "Editar" usa `data-turbo-frame: "_top"` — navega para página completa
- Link "Excluir" usa `data-turbo-method: delete` + `data-turbo-confirm` — requer JS
- Destroy remove a row via `turbo_stream.remove` sem reload
- Cada row tem `id="task_#{id}"` via `dom_id`

### Links de ação — aria-label exatos
```
"Editar tarefa #{task.name}"
"Excluir tarefa #{task.name}"
```

### Filtro de período padrão
A listagem filtra por `Date.current.all_month`. Sempre usar `start_date: Date.current` nas factories para tasks aparecerem na listagem sem filtros adicionais.

---

## Acceptance Criteria

- [ ] AC1: `spec/system/tasks_spec.rb` criado (não `time_entries_spec.rb`)
- [ ] AC2: Spec cobre visualização da listagem com coluna "Ações"
- [ ] AC3: Spec cobre navegação para formulário de edição via link "Editar"
- [ ] AC4: Spec cobre edição de task com verificação de flash message
- [ ] AC5: Spec cobre destroy com `js: true` e `accept_confirm`
- [ ] AC6: Spec verifica que task é removida da lista após destroy
- [ ] AC7: `bundle exec rspec spec/system/tasks_spec.rb` passa 100%
- [ ] AC8: Testes sem JS usam rack_test (rápido); destroy usa `js: true`

---

## Dev Notes

### Criar pasta e arquivo
```bash
mkdir -p spec/system
```

### Conteúdo do spec — spec/system/tasks_spec.rb

```ruby
require "rails_helper"

RSpec.describe "Tasks", type: :system do
  let(:user) { create(:user) }
  let(:company) { create(:company) }
  let(:project) { create(:project, company: company) }

  before do
    visit new_session_path
    fill_in "Email", with: user.email_address
    fill_in "Password", with: "Password123!"
    click_button "Entrar"
  end

  describe "index" do
    context "with existing tasks" do
      let!(:task) { create(:task, start_date: Date.current, company: company, project: project) }

      it "displays tasks list with Ações column" do
        visit tasks_path
        expect(page).to have_css("th", text: "Ações")
        expect(page).to have_content(task.name)
      end

      it "shows Editar and Excluir links for each task" do
        visit tasks_path
        expect(page).to have_link("Editar", href: edit_task_path(task))
        expect(page).to have_css("a[aria-label='Excluir tarefa #{task.name}']")
      end
    end

    it "shows empty state when no tasks exist" do
      visit tasks_path
      expect(page).to have_content("Nenhuma tarefa encontrada")
    end
  end

  describe "edit" do
    let!(:task) { create(:task, start_date: Date.current, company: company, project: project) }

    it "navigates to edit form via Editar link" do
      visit tasks_path
      click_link "Editar tarefa #{task.name}"
      expect(current_path).to eq(edit_task_path(task))
      expect(page).to have_field("Nome da Tarefa", with: task.name)
    end

    it "updates task and shows flash message" do
      visit edit_task_path(task)
      fill_in "Nome da Tarefa", with: "Nome atualizado pelo sistema"
      click_button "Salvar Alterações"
      expect(page).to have_content("Tarefa atualizada com sucesso")
      expect(task.reload.name).to eq("Nome atualizado pelo sistema")
    end

    it "shows validation errors when name is blank" do
      visit edit_task_path(task)
      fill_in "Nome da Tarefa", with: ""
      click_button "Salvar Alterações"
      expect(page).to have_content("erro")
    end
  end

  describe "destroy", js: true do
    let!(:task) { create(:task, start_date: Date.current, company: company, project: project) }

    it "removes task from list after confirmation" do
      visit tasks_path
      expect(page).to have_content(task.name)
      accept_confirm do
        click_link "Excluir tarefa #{task.name}"
      end
      expect(page).not_to have_content(task.name)
      expect(Task.find_by(id: task.id)).to be_nil
    end
  end
end
```

### Dicas importantes

1. **start_date: Date.current** — obrigatório para tasks aparecerem na listagem (filtro mês atual).

2. **turbo_confirm com rack_test** — `data-turbo-confirm` não dispara diálogo com rack_test. Destroy DEVE usar `js: true`.

3. **accept_confirm** — Capybara usa `accept_confirm { ... }` para aceitar diálogos JS nativos. Com turbo_confirm o diálogo é nativo do browser.

4. **email_address** — o campo do modelo User é `email_address` (Rails 8 authentication), não `email`. Verificar antes de usar `fill_in`.

5. **Criar task com company/project explícitos** — a factory cria automaticamente, mas associações explícitas garantem previsibilidade nos testes.

### Rodar specs
```bash
docker exec -e RAILS_ENV=test cronos-poc-web-1 bundle exec rspec spec/system/tasks_spec.rb --format documentation
```

---

## Guardrails

- **NUNCA** usar `TimeEntry`, `time_entries_spec.rb`, ou `new_time_entry_path` — não existem
- **SEMPRE** `start_date: Date.current` para tasks aparecerem na listagem
- **SEMPRE** `js: true` no teste de destroy
- **SEMPRE** `user.email_address` (não `user.email`) no login
- **NÃO** testar seleção de projeto via rack_test (AJAX não funciona sem JS)
- **NÃO** usar `time` para horários — Task não tem campos de hora (só `estimated_hours_hm`)

---

## Dev Agent Record

_(Preencher após implementação)_

### Checklist de Implementação
- [ ] `spec/system/tasks_spec.rb` criado
- [ ] Testes de index/listagem passando
- [ ] Testes de edição passando
- [ ] Teste de destroy (js: true) passando
- [ ] `bundle exec rspec spec/system/tasks_spec.rb` — 100% verde

### Notas de Implementação
_(Preencher pelo dev agent)_
