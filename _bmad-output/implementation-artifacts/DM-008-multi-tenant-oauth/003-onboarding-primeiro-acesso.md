# Story 9.3: Onboarding — Primeiro Acesso de Novo Usuário

**Status:** ready-for-dev (depende de 9.1 e 9.2)
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
- [ ] **AC1.1:** "Primeiro acesso" = `current_user.companies.count == 0` (não há Company criada)
- [ ] **AC1.2:** `DashboardController#index` detecta essa condição e renderiza partial diferente
- [ ] **AC1.3:** Após criar a primeira Company, dashboard volta ao layout normal

### AC2 — Tela de onboarding (`_onboarding.html.erb`)
- [ ] **AC2.1:** Mensagem de boas-vindas: "Olá, {first_name}! Vamos configurar sua primeira empresa em 2 passos:"
- [ ] **AC2.2:** Passo 1 — **Card "Criar Empresa"** com botão grande "Criar Empresa" → abre modal/redirect para `/companies/new`
- [ ] **AC2.3:** Passo 2 — **Card "Criar Projeto"** (visualmente "trancado" enquanto não houver Company) com texto "Crie primeiro uma Empresa para depois adicionar Projetos"
- [ ] **AC2.4:** Após Company criada, Passo 2 destrava e mostra botão "Criar Projeto" → redirect para `/projects/new`
- [ ] **AC2.5:** Passo 3 — quando já houver 1 Project, mostrar botão "Criar Primeira Tarefa" → `/tasks/new`
- [ ] **AC2.6:** Quando user tiver ao menos 1 Task, onboarding desaparece definitivamente

### AC3 — Lógica de progresso
- [ ] **AC3.1:** Helper/concern `OnboardingState` que calcula em qual passo o usuário está:
  - `step_1_pending`: 0 companies
  - `step_2_pending`: 1+ companies, 0 projects
  - `step_3_pending`: 1+ projects, 0 tasks
  - `completed`: 1+ tasks
- [ ] **AC3.2:** Estado calculado server-side por request (não armazenar em coluna no User — derivado dos counts)

### AC4 — UX em formulários durante onboarding
- [ ] **AC4.1:** `/companies/new` durante onboarding mostra header "Passo 1 de 3 — Criar Empresa"
- [ ] **AC4.2:** Após criar Company com sucesso, redirect direto para `/projects/new` (não para `/companies`) com flash "Empresa criada! Agora crie seu primeiro projeto."
- [ ] **AC4.3:** `/projects/new` durante onboarding mostra header "Passo 2 de 3 — Criar Projeto"
- [ ] **AC4.4:** Após criar Project, redirect para dashboard `/` (mostra onboarding com Passo 3 ativo)
- [ ] **AC4.5:** Após criar primeira Task, flash de sucesso "Configuração concluída! 🎉" e dashboard normal

### AC5 — Não atrapalhar usuários existentes
- [ ] **AC5.1:** Usuário Igor (que já tem dados após backfill 9.2) **nunca** vê onboarding — `companies.count >= 1` desde o primeiro login
- [ ] **AC5.2:** Onboarding aparece somente para users com 0 companies — autoexcludente

### AC6 — Cobertura
- [ ] **AC6.1:** Spec dashboard: user novo (0 companies) vê partial `_onboarding` com botão "Criar Empresa"
- [ ] **AC6.2:** Spec dashboard: user com 1 company / 0 projects vê passo 2 ativo
- [ ] **AC6.3:** Spec dashboard: user com 1 task vê dashboard normal
- [ ] **AC6.4:** Spec controller: criar Company durante onboarding redireciona para `/projects/new`
- [ ] **AC6.5:** System spec/Playwright: fluxo completo novo user — login Google (mock) → onboarding → cria company → cria project → cria task → dashboard normal

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
