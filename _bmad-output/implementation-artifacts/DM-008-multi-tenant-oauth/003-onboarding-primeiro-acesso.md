# Story 9.3: Onboarding — Primeiro Acesso de Novo Usuário

**Status:** in-progress (depende de 9.1 e 9.2)
**Domínio:** DM-008-multi-tenant-oauth
**Data:** 2026-05-15
**Epic:** Epic 9 — Multi-Tenancy & Google OAuth
**Story ID:** 9.3
**Story Key:** 9-3-onboarding-primeiro-acesso
**Prioridade:** high

---

## Contexto

Com OAuth (9.1) e multi-tenancy (9.2), um novo usuário entra via Google e cai em um dashboard **vazio** — zero Companies, Projects, Tasks. A primeira impressão é confusa: "o que eu faço agora?".

Esta story implementa um **onboarding mínimo** no primeiro acesso, guiando o usuário para criar sua primeira Company e Project antes de poder lançar tarefas.

> Princípio: ship the smallest thing that validates the assumption — sem tour interativo nem wizard de 5 passos. Apenas uma tela de "primeiros passos" com 2 CTAs claros.

---

## História do Usuário

**Como** novo usuário que acabou de logar via Google,
**Quero** entender em 5 segundos o que preciso fazer primeiro,
**Para** não me sentir perdido em um dashboard vazio e abandonar o produto.

---

## Critérios de Aceite

### AC1 — Detecção de primeiro acesso
- [x] **AC1.1:** "Primeiro acesso" = `current_user.companies.count == 0` (não há Company criada)
- [x] **AC1.2:** `DashboardController#index` detecta essa condição e renderiza partial diferente
- [x] **AC1.3:** Após criar a primeira Company, dashboard volta ao layout normal

### AC2 — Tela de onboarding (`_onboarding.html.erb`)
- [x] **AC2.1:** Mensagem de boas-vindas: "Olá, {first_name}! Vamos configurar sua primeira empresa em 2 passos:"
- [x] **AC2.2:** Passo 1 — **Card "Criar Empresa"** com botão grande "Criar Empresa" → abre modal/redirect para `/companies/new`
- [x] **AC2.3:** Passo 2 — **Card "Criar Projeto"** (visualmente "trancado" enquanto não houver Company) com texto "Crie primeiro uma Empresa para depois adicionar Projetos"
- [x] **AC2.4:** Após Company criada, Passo 2 destrava e mostra botão "Criar Projeto" → redirect para `/projects/new`
- [x] **AC2.5:** Passo 3 — quando já houver 1 Project, mostrar botão "Criar Primeira Tarefa" → `/tasks/new`
- [x] **AC2.6:** Quando user tiver ao menos 1 Task, onboarding desaparece definitivamente

### AC3 — Lógica de progresso
- [x] **AC3.1:** Helper/concern `OnboardingState` que calcula em qual passo o usuário está:
  - `step_1_pending`: 0 companies
  - `step_2_pending`: 1+ companies, 0 projects
  - `step_3_pending`: 1+ projects, 0 tasks
  - `completed`: 1+ tasks
- [x] **AC3.2:** Estado calculado server-side por request (não armazenar em coluna no User — derivado dos counts)

### AC4 — UX em formulários durante onboarding
- [x] **AC4.1:** `/companies/new` durante onboarding mostra header "Passo 1 de 3 — Criar Empresa"
- [x] **AC4.2:** Após criar Company com sucesso, redirect direto para `/projects/new` (não para `/companies`) com flash "Empresa criada! Agora crie seu primeiro projeto."
- [x] **AC4.3:** `/projects/new` durante onboarding mostra header "Passo 2 de 3 — Criar Projeto"
- [x] **AC4.4:** Após criar Project, redirect para dashboard `/` (mostra onboarding com Passo 3 ativo)
- [x] **AC4.5:** Após criar primeira Task, flash de sucesso "Configuração concluída! 🎉" e dashboard normal

### AC5 — Não atrapalhar usuários existentes
- [x] **AC5.1:** Usuário Igor (que já tem dados após backfill 9.2) **nunca** vê onboarding — `companies.count >= 1` desde o primeiro login
- [x] **AC5.2:** Onboarding aparece somente para users com 0 companies — autoexcludente

### AC6 — Cobertura
- [x] **AC6.1:** Spec dashboard: user novo (0 companies) vê partial `_onboarding` com botão "Criar Empresa"
- [x] **AC6.2:** Spec dashboard: user com 1 company / 0 projects vê passo 2 ativo
- [x] **AC6.3:** Spec dashboard: user com 1 task vê dashboard normal
- [x] **AC6.4:** Spec controller: criar Company durante onboarding redireciona para `/projects/new`
- [x] **AC6.5:** Request specs cobrem o fluxo completo (login email/senha → onboarding step_1 → cria company → redirect /projects/new → cria project → redirect / → onboarding step_3 → cria task → dashboard normal). Validação manual via Playwright executada pelo pipeline /implement-story.

---

## Análise Técnica

### Helper

```ruby
# app/helpers/onboarding_helper.rb
module OnboardingHelper
  def onboarding_step(user)
    return :completed if user.tasks.any?
    return :step_3 if user.projects.any?
    return :step_2 if user.companies.any?
    :step_1
  end

  def onboarding_active?(user)
    onboarding_step(user) != :completed
  end
end
```

### Partial `_onboarding.html.erb`

```erb
<div class="max-w-2xl mx-auto py-12">
  <h1 class="text-3xl text-white font-bold mb-2">
    Olá, <%= current_user.name.split.first %>! 👋
  </h1>
  <p class="text-gray-400 mb-8">
    Vamos configurar seu Cronos POC em 3 passos rápidos.
  </p>

  <div class="space-y-4">
    <%= render "onboarding/step",
          number: 1,
          title: "Criar Empresa",
          description: "Cadastre a primeira empresa para a qual você trabalha.",
          cta: "Criar Empresa",
          path: new_company_path,
          state: step_state(:step_1) %>

    <%= render "onboarding/step",
          number: 2,
          title: "Criar Projeto",
          description: "Adicione um projeto dentro da empresa.",
          cta: "Criar Projeto",
          path: new_project_path,
          state: step_state(:step_2) %>

    <%= render "onboarding/step",
          number: 3,
          title: "Lançar Primeira Tarefa",
          description: "Crie uma tarefa para começar a registrar horas.",
          cta: "Criar Tarefa",
          path: new_task_path,
          state: step_state(:step_3) %>
  </div>
</div>
```

Cada step pode estar em 3 estados: `:pending` (acessível, destacado), `:locked` (cinza, com cadeado), `:done` (check verde).

### Redirect após create durante onboarding

```ruby
# CompaniesController#create
def create
  @company = current_user.companies.create(company_params)
  if @company.persisted?
    if helpers.onboarding_active?(current_user)
      redirect_to new_project_path, notice: "Empresa criada! Agora crie seu primeiro projeto."
    else
      redirect_to companies_path, notice: "Empresa criada com sucesso."
    end
  else
    render :new, status: :unprocessable_content
  end
end
```

---

## Arquivos a Criar/Modificar

| Arquivo | Ação |
|---------|------|
| `app/helpers/onboarding_helper.rb` | Criar |
| `app/views/dashboard/_onboarding.html.erb` | Criar — tela principal de onboarding |
| `app/views/onboarding/_step.html.erb` | Criar — partial reutilizável de cada passo |
| `app/views/dashboard/index.html.erb` | If `onboarding_active?(current_user)` → render `_onboarding` |
| `app/controllers/companies_controller.rb` | Redirect condicional pós-create |
| `app/controllers/projects_controller.rb` | Redirect condicional pós-create |
| `app/controllers/tasks_controller.rb` | Flash especial pós-primeira-task |
| `spec/helpers/onboarding_helper_spec.rb` | Specs do helper |
| `spec/requests/dashboard_onboarding_spec.rb` | Specs dos 4 estados (step_1/2/3/completed) |
| `spec/system/onboarding_flow_spec.rb` (opcional) | Fluxo completo |

---

## Dependências

- **Requer:** story 9.1 (User com Google) e story 9.2 (multi-tenancy ativo)

---

## Observações

- **Sem persistir estado de onboarding** — derivado dos counts. Se o user deletar todas as companies, o onboarding volta. Isso é OK (e até desejado).
- **Sem analytics agora** — depois de validar o fluxo, podemos adicionar tracking de drop-off em cada passo (ex: PostHog, Plausible).
- **Sem skip explícito** — não há "Pular onboarding". Se o usuário não quer criar Company, ele simplesmente não consegue usar o app (que precisa de Company para tudo).

---

## Estimativa

**2 story points** (~3h) — helper + 2 partials + ajustes em 3 controllers + 4-5 specs.

---

## Dev Agent Record

**Implementado por:** Amelia (bmad-agent-dev) — 2026-05-26
**Branch:** `feature-003-onboarding-primeiro-acesso`

### Decisões / Notas
- Helper `OnboardingHelper` calcula estado server-side via counts (`exists?` em vez de `any?` para evitar carga). Sem coluna persistida no User.
- Adicionado helper `step_state(step, current_step)` para mapear `:pending`/`:locked`/`:done`, mantendo lógica de visualização fora do partial.
- `DashboardController#index` faz curto-circuito quando `onboarding_active?`, evitando queries pesadas de KPIs para usuários novos.
- Flash de conclusão usa emoji 🎉 inline (consistente com o estilo do projeto — sem i18n específico).
- Tasks pré-existentes detectadas via `Current.user.tasks.exists?` antes do `save` para evitar race com a nova task ainda não persistida.
- Partial `_step` é reutilizável; estado `:locked` renderiza `<span role="button" aria-disabled="true">` (sem link) para acessibilidade.

### Ajustes em specs existentes (regressão por mudança de fluxo)
Specs que faziam `get root_path` sem dados pré-existentes agora caem no onboarding. Adicionado seed de Company+Project+Task em:
- `spec/requests/dashboard_kpis_spec.rb`
- `spec/requests/dashboard_modal_nova_tarefa_spec.rb`
- `spec/requests/dashboard_quick_actions_spec.rb`
- `spec/requests/dashboard_tasks_month_spec.rb` (contexto "no tasks")
- `spec/requests/accessibility_spec.rb`
- `spec/requests/companies_spec.rb` (POST /companies fora do onboarding)
- `spec/requests/projects_spec.rb` (POST /projects fora do onboarding)
- `spec/requests/tasks_spec.rb` (POST /tasks fora do onboarding)
- `spec/controllers/tasks_controller_spec.rb` (POST #create fora do onboarding)

### Resultado da Suite (após QA round 1)
- **Specs:** 1082 examples, 0 failures
- **Cobertura SimpleCov:** 100.0% (777/777 linhas)

---

## QA Round 1 — 18 findings aplicados (2026-05-26)

Findings registrados em `~/.claude/projects/-home-igor-rails-app-cronos-poc/memory/feedback_qa_9_3_*.md`.

### CRITICAL (1)
- **C1** — Cacheado `@onboarding_state = OnboardingState.new(Current.user)` no `DashboardController#index`; partial recebe via local; gate da view passou a usar `@onboarding_state.active?`. Eliminadas chamadas redundantes (3→1 bateria de EXISTS).

### HIGH (5)
- **H1** — `task_create_notice` computada uma vez e usada em AMBOS os branches (HTML e Turbo-Frame=modal). Layout passou a ter `<div id="flash">` persistente; modal injeta `turbo_stream.update("flash", partial: "shared/flash")` com `flash.now`. Cobertura: dois novos specs (primeira task via modal + tasks subsequentes via modal).
- **H2** — `onboarding_active_before_save = OnboardingState.new(Current.user).active?` capturado ANTES do `@record.save` em `CompaniesController#create` e `ProjectsController#create` (alinhado ao padrão já adotado em `TasksController#create`).
- **H3** — Extraído `app/models/onboarding_state.rb` (PORO) com `.step`, `.active?`, `.step_state(target)`. Helper Rails passou a conter apenas formatadores de view (`display_first_name`, `onboarding_step_path`). Controllers chamam o PORO direto — fim do `helpers.X` em controller.
- **H4** — Criado `spec/support/onboarding_helpers.rb` com `complete_onboarding_for(user)`. Substituídos seeds duplicados em 9 specs (dashboard_kpis, dashboard_modal_nova_tarefa, dashboard_quick_actions, dashboard_tasks_month, accessibility, companies, projects, tasks request, tasks_controller).
- **H5** — `display_first_name(user)` com triple-fallback (`name.split.first → email prefix → "amigo"`) + spec dedicado cobrindo todos os caminhos (incluindo `user.nil?`).

### MEDIUM (7)
- **M1** — `OnboardingState#step_state` levanta `ArgumentError` para step desconhecido (loud failure). `OnboardingHelper#onboarding_step_path` faz o mesmo.
- **M2** — `OnboardingState#step_state` retorna `:done` para qualquer target quando `current_step == :completed` (guard no topo do método). Spec cobre os 4 estados.
- **M3** — Trocado `<ol class="list-none">` por `<div role="list">`; cards passaram de `role="group"` para `role="listitem"`. Badges visuais 1/2/3 ficam como única numeração (sem duplicação no SR).
- **M4** — Novo spec em `dashboard_onboarding_spec.rb` cobrindo `POST /projects` em `:step_3` (segundo project, ainda no onboarding) — confirma redirect para `root_path`.
- **M5** — Comentário ERB explícito em `_step.html.erb` documentando que `data-onboarding-state` é hook de teste (sem Stimulus controller).
- **M6** — Bloco `onboarding:` adicionado em `config/locales/pt-BR.yml` (greeting, intro, steps.*.{title,description,locked_description,cta,header}, flashes.*). Controllers e partials usam `t(...)`.
- **M7** — `aria-live="polite"` nos `<p data-onboarding-step-label>` em `companies/new.html.erb` e `projects/new.html.erb`. Dois novos specs em `accessibility_spec.rb` verificando a presença do atributo.

### LOW (5)
- **L1** — `STEPS` é `private_constant` em `OnboardingState`. Constante removida do helper.
- **L2** — Strings dos cards (`title`, `description`, `cta`) consumidas via `t("onboarding.steps.step_N.X")` no partial `_onboarding`.
- **L3** — `_step.html.erb_spec.rb` agora itera `[1, 2, 3].each do |n|` cobrindo todos os estados × números (garante interpolação `step_#{number}` sem hardcode).
- **L4** — Cases em `_step.html.erb` trocaram `else` por `when :locked` explícito + `else raise ArgumentError`. Spec cobre o branch de erro (ActionView wrap).
- **L5** — Removido comentário incorreto sobre "auto-include em controllers só com `helpers.`" — helper agora é minimalista com docstring precisa.

### Resultado da Suite (após QA round 1)
- **Specs:** 1120 examples, 0 failures (+38 specs novos)
- **Cobertura SimpleCov:** 100.0% (802/802 linhas)

---

## File List

### Criados
- `app/models/onboarding_state.rb` — PORO de estado (QA #H3)
- `app/helpers/onboarding_helper.rb` — apenas formatadores (display_first_name + onboarding_step_path)
- `app/views/dashboard/_onboarding.html.erb` — partial de onboarding (i18n)
- `app/views/onboarding/_step.html.erb` — partial reutilizável de cada passo
- `spec/models/onboarding_state_spec.rb` — specs do PORO (cache, M1, M2)
- `spec/helpers/onboarding_helper_spec.rb` — display_first_name + onboarding_step_path
- `spec/requests/dashboard_onboarding_spec.rb` — fluxos completos incluindo M4 + H1 modal
- `spec/views/onboarding/_step.html.erb_spec.rb` — loop [1,2,3] × estados + L4 raise
- `spec/support/onboarding_helpers.rb` — `complete_onboarding_for(user)` (QA #H4)

### Modificados
- `app/controllers/dashboard_controller.rb` — `@onboarding_state` cacheado (QA #C1)
- `app/controllers/companies_controller.rb` — pre-save check + i18n (QA #H2, #M6)
- `app/controllers/projects_controller.rb` — pre-save check + i18n (QA #H2, #M6)
- `app/controllers/tasks_controller.rb` — flash modal + i18n (QA #H1, #M6)
- `app/views/layouts/application.html.erb` — `<div id="flash">` persistente (QA #H1)
- `app/views/dashboard/index.html.erb` — gate via `@onboarding_state.active?`
- `app/views/companies/new.html.erb` — i18n + aria-live + OnboardingState direto (QA #H3, #M6, #M7)
- `app/views/projects/new.html.erb` — i18n + aria-live + OnboardingState direto (QA #H3, #M6, #M7)
- `config/locales/pt-BR.yml` — bloco `onboarding.*` (QA #L2, #M6)
- `spec/requests/accessibility_spec.rb` — role=list + aria-live + helper centralizado (QA #M3, #M7, #H4)
- `spec/requests/mobile_first_spec.rb` — cobertura onboarding mobile
- `spec/requests/dashboard_kpis_spec.rb` — `complete_onboarding_for` (QA #H4)
- `spec/requests/dashboard_modal_nova_tarefa_spec.rb` — `complete_onboarding_for` (QA #H4)
- `spec/requests/dashboard_quick_actions_spec.rb` — `complete_onboarding_for` (QA #H4)
- `spec/requests/dashboard_tasks_month_spec.rb` — `complete_onboarding_for` (QA #H4)
- `spec/requests/companies_spec.rb` — `complete_onboarding_for` (QA #H4)
- `spec/requests/projects_spec.rb` — `complete_onboarding_for` (QA #H4)
- `spec/requests/tasks_spec.rb` — `complete_onboarding_for` (QA #H4)
- `spec/controllers/tasks_controller_spec.rb` — `complete_onboarding_for` (QA #H4)
