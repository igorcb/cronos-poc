# Story 7.1: Implementar Edição de Tasks na Listagem

**Status:** done
**Domínio:** DM-004-registro-tempo
**Data:** 2026-04-21
**Epic:** Epic 7 — Edição & Correção de Entradas
**Story ID:** 7.1
**Story Key:** 7-1-implementar-edit-update-de-timeentries

---

## Story

**Como** Igor,
**Quero** acessar links de Editar e Excluir diretamente na listagem de tarefas,
**Para que** eu possa corrigir erros e remover entradas incorretas sem sair do contexto.

---

## Contexto Técnico Crítico

### Modelos existentes (NUNCA usar TimeEntry — não existe)
- `Task` — model principal, campos: `name`, `company_id`, `project_id`, `start_date`, `estimated_hours`, `validated_hours`, `notes`, `status`
- `TaskItem` — itens de tarefa com `hours_worked`
- `Company`, `Project` — associações de Task

### Controller já implementado
O `TasksController` já possui `edit`, `update`, `destroy` com `before_action :set_task`.
**NÃO recriar esses métodos.** O controller está completo em `app/controllers/tasks_controller.rb`.

```ruby
# Já existe — apenas referência
def edit
  @companies = Company.active.order(:name)
end

def update
  if @task.update(task_params)
    respond_to do |format|
      format.turbo_stream { render turbo_stream: [...] }
      format.html { redirect_to tasks_path, notice: "Tarefa atualizada com sucesso" }
    end
  else
    @companies = Company.active.order(:name)
    render :edit, status: :unprocessable_entity
  end
end

def destroy
  @task.destroy
  respond_to do |format|
    format.turbo_stream { render turbo_stream: [...] }
    format.html { redirect_to tasks_path, notice: "Tarefa removida com sucesso" }
  end
end
```

### Views já existentes
- `app/views/tasks/edit.html.erb` — formulário de edição já implementado com Tailwind dark theme, WCAG, mobile-first
- `app/views/tasks/new.html.erb` — formulário de criação (referência de estilo)

### O que FALTA implementar
O `TaskCardComponent` (`app/components/task_card_component.html.erb`) renderiza cada linha da tabela mas **não tem links de Editar/Excluir**. Esta story adiciona essas ações ao componente.

### TaskCardComponent atual
```html
<tr class="hover:bg-gray-700 transition-colors border-b border-gray-700">
  <td>...</td> <!-- Data -->
  <td>...</td> <!-- Nome -->
  <td>...</td> <!-- Empresa -->
  <td>...</td> <!-- Projeto -->
  <td>...</td> <!-- Status badge -->
  <td>...</td> <!-- Estimado -->
  <td>...</td> <!-- Validado -->
  <td>...</td> <!-- Valor -->
  <!-- FALTA: coluna Ações com links Editar e Excluir -->
</tr>
```

### index.html.erb — tabela
A tabela em `app/views/tasks/index.html.erb` tem `<thead>` com colunas fixas. É necessário adicionar coluna "Ações" no cabeçalho.

### Rotas disponíveis
```
GET    /tasks/:id/edit  → tasks#edit
PATCH  /tasks/:id       → tasks#update
DELETE /tasks/:id       → tasks#destroy
```

### Padrão de confirmação de destroy
Usar `data: { turbo_method: :delete, turbo_confirm: "Tem certeza que deseja remover esta tarefa?" }` no link de excluir — sem JavaScript customizado.

### Turbo Stream — destroy já funciona
O `destroy` action já responde com `turbo_stream` que atualiza `daily_total` e `company_monthly_totals`. A row da tabela precisa ter um `id` para poder ser removida via Turbo Stream: `id: dom_id(task)`.

---

## Acceptance Criteria

- [ ] AC1: Coluna "Ações" adicionada no `<thead>` da tabela em `index.html.erb`
- [ ] AC2: `TaskCardComponent` renderiza links "Editar" e "Excluir" na última coluna
- [ ] AC3: Link "Editar" direciona para `edit_task_path(task)` — abre `edit.html.erb` já existente
- [ ] AC4: Link "Excluir" usa `turbo_method: :delete` com `turbo_confirm` de confirmação
- [ ] AC5: Ao excluir via Turbo Stream, a row é removida da tabela sem reload de página
- [ ] AC6: `<tr>` do TaskCardComponent tem `id: dom_id(task)` para Turbo Stream target
- [ ] AC7: Após edição bem-sucedida, redireciona para `tasks_path` com flash "Tarefa atualizada com sucesso"
- [ ] AC8: Spec cobre GET#edit, PATCH#update (sucesso e falha), DELETE#destroy
- [ ] AC9: Links de ação têm `aria-label` descritivo com nome da tarefa (acessibilidade WCAG)

---

## Dev Notes

### 1. Adicionar coluna Ações no thead (index.html.erb)

Localizar o `<thead>` existente e adicionar:
```html
<th scope="col" class="px-4 py-3 text-left text-xs font-medium text-gray-400 uppercase tracking-wider">Ações</th>
```

### 2. Atualizar TaskCardComponent (task_card_component.html.erb)

Adicionar `id` na `<tr>` e nova `<td>` de ações:
```html
<tr id="<%= dom_id(task) %>" class="hover:bg-gray-700 transition-colors border-b border-gray-700">
  <!-- ... colunas existentes ... -->
  <td class="px-4 py-3 text-sm">
    <div class="flex gap-2">
      <%= link_to "Editar", edit_task_path(task),
          class: "text-blue-400 hover:text-blue-300 font-medium transition",
          aria: { label: "Editar tarefa #{task.name}" } %>
      <%= link_to "Excluir", task_path(task),
          data: { turbo_method: :delete, turbo_confirm: "Tem certeza que deseja remover \"#{task.name}\"?" },
          class: "text-red-400 hover:text-red-300 font-medium transition",
          aria: { label: "Excluir tarefa #{task.name}" } %>
    </div>
  </td>
</tr>
```

### 3. Destroy com Turbo Stream — remover row

No `TasksController#destroy`, adicionar remoção da row à resposta turbo_stream:

```ruby
def destroy
  @task.destroy

  respond_to do |format|
    format.turbo_stream do
      render turbo_stream: [
        turbo_stream.remove(dom_id(@task)),
        turbo_stream.replace("daily_total", partial: "tasks/daily_total", locals: { daily_total: calculate_daily_total }),
        turbo_stream.replace("company_monthly_totals", partial: "tasks/company_monthly_totals", locals: { totals: calculate_company_totals })
      ]
    end
    format.html { redirect_to tasks_path, notice: "Tarefa removida com sucesso" }
  end
end
```

### 4. Verificar destroy com before_destroy

Se Task tiver `before_destroy` callbacks, checar retorno:
```ruby
# No controller, verificar se destroy falhou
if @task.destroy
  # sucesso
else
  redirect_to tasks_path, alert: "Não foi possível remover a tarefa"
end
```

### 5. Specs a criar/atualizar

Arquivo: `spec/controllers/tasks_controller_spec.rb`

```ruby
describe "GET #edit" do
  it "returns http success" do
    task = create(:task)
    get :edit, params: { id: task.id }
    expect(response).to have_http_status(:success)
  end
end

describe "PATCH #update" do
  context "with valid params" do
    it "updates task and redirects" do
      task = create(:task)
      patch :update, params: { id: task.id, task: { name: "Novo nome" } }
      expect(response).to redirect_to(tasks_path)
      expect(task.reload.name).to eq("Novo nome")
    end
  end

  context "with invalid params" do
    it "renders edit with unprocessable_entity" do
      task = create(:task)
      patch :update, params: { id: task.id, task: { name: "" } }
      expect(response).to have_http_status(:unprocessable_entity)
      expect(response).to render_template(:edit)
    end
  end
end

describe "DELETE #destroy" do
  it "destroys task and redirects" do
    task = create(:task)
    expect { delete :destroy, params: { id: task.id } }.to change(Task, :count).by(-1)
    expect(response).to redirect_to(tasks_path)
  end
end
```

---

## Guardrails

- **NÃO** recriar `edit`, `update`, `destroy` no controller — já existem
- **NÃO** usar `TimeEntry` — modelo não existe no projeto
- **NÃO** criar novo Stimulus controller — não é necessário
- **NÃO** recriar `edit.html.erb` — já existe com estilo completo
- **SEMPRE** usar `dom_id(task)` para IDs de Turbo Stream
- **SEMPRE** incluir `aria-label` nos links de ação (WCAG AC9)
- **SEMPRE** testar destroy com `change(Task, :count).by(-1)`

---

## Dev Agent Record

_(Preencher após implementação)_

### Checklist de Implementação
- [ ] `<th>` Ações adicionado no thead de index.html.erb
- [ ] `id: dom_id(task)` adicionado na `<tr>` do TaskCardComponent
- [ ] Links Editar e Excluir adicionados no TaskCardComponent
- [ ] `turbo_stream.remove(dom_id(@task))` adicionado no destroy
- [ ] Specs de edit/update/destroy passando
- [ ] Testado via browser: editar task, excluir task com confirmação

### Notas de Implementação
_(Preencher pelo dev agent)_
