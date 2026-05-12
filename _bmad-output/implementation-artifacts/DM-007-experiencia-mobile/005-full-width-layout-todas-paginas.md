# Story 7.5: Aproveitar Largura Total da Tela em Todas as Páginas

**Status:** ready-for-dev
**Domínio:** DM-007-experiencia-mobile
**Data:** 2026-05-12
**Epic:** Epic 8 — Experiência Mobile & Responsividade
**Story ID:** 7.5
**Story Key:** 7-5-full-width-layout-todas-paginas

---

## Contexto

Hoje o layout aplica `max-w-7xl` (1280px) no container principal do `application.html.erb`, limitando o aproveitamento da tela em monitores wide e ultra-wide. Em monitores 1440p/1920p+ sobra muito espaço vazio nas laterais, reduzindo densidade de informação no dashboard e nas listagens.

Os formulários também usam `sm:max-w-2xl` / `sm:max-w-lg`, herdando a mesma limitação.

Esta story expande o container para `max-w-screen-2xl` (1536px) em todo o app — incluindo formulários — mantendo o comportamento mobile-first inalterado (em telas pequenas, `w-full` continua sendo respeitado via breakpoint `sm:`).

---

## História do Usuário

**Como** Igor,
**Quero** que todas as páginas aproveitem a largura total da tela em monitores wide,
**Para** ver mais informação por viewport sem rolar (dashboard com mais colunas visíveis, listagens com mais linhas/colunas, formulários menos comprimidos), mantendo o mobile funcional.

---

## Critérios de Aceite

- [ ] **AC1:** `application.html.erb` — substituir `max-w-7xl` por `max-w-screen-2xl` nas 3 ocorrências (navbar, main, footer)
- [ ] **AC2:** `tasks/index.html.erb` — substituir `max-w-7xl` por `max-w-screen-2xl`
- [ ] **AC3:** `shared/_flash.html.erb` — substituir `max-w-7xl` por `max-w-screen-2xl`
- [ ] **AC4:** Formulários `tasks/new.html.erb` (modal + view normal) e `tasks/edit.html.erb` — substituir `sm:max-w-2xl` por `sm:max-w-screen-2xl`
- [ ] **AC5:** Formulários `companies/new.html.erb`, `companies/edit.html.erb`, `projects/new.html.erb`, `projects/edit.html.erb`, `profiles/show.html.erb` — substituir `sm:max-w-lg` por `sm:max-w-screen-2xl`
- [ ] **AC6:** Telas de autenticação (`sessions/new`, `passwords/new`, `passwords/edit`) — manter `max-w-md` (login centralizado é padrão UX consagrado) — **NÃO alterar**
- [ ] **AC7:** Modal `task_items/_modal_form.html.erb` — manter `max-w-lg` (modal sempre estreito por UX) — **NÃO alterar**
- [ ] **AC8:** Mobile (< 640px) continua usando `w-full` — sem regressão; validar em 320px/375px/414px
- [ ] **AC9:** Especificações de mobile-first (`mobile_first_spec`, `accessibility_spec`) continuam passando sem alteração

---

## Análise Técnica

### Mapeamento das alterações

| Arquivo | De | Para |
|---------|-----|------|
| `app/views/layouts/application.html.erb` (3x) | `max-w-7xl mx-auto px-4 sm:px-6 lg:px-8` | `max-w-screen-2xl mx-auto px-4 sm:px-6 lg:px-8` |
| `app/views/shared/_flash.html.erb` | `max-w-7xl mx-auto ...` | `max-w-screen-2xl mx-auto ...` |
| `app/views/tasks/index.html.erb` | `max-w-7xl mx-auto` | `max-w-screen-2xl mx-auto` |
| `app/views/tasks/new.html.erb` (modal + normal) | `sm:max-w-2xl` | `sm:max-w-screen-2xl` |
| `app/views/tasks/edit.html.erb` | `sm:max-w-2xl` | `sm:max-w-screen-2xl` |
| `app/views/companies/new.html.erb` | `sm:max-w-lg` | `sm:max-w-screen-2xl` |
| `app/views/companies/edit.html.erb` | `sm:max-w-lg` | `sm:max-w-screen-2xl` |
| `app/views/projects/new.html.erb` | `sm:max-w-lg` | `sm:max-w-screen-2xl` |
| `app/views/projects/edit.html.erb` | `sm:max-w-lg` | `sm:max-w-screen-2xl` |
| `app/views/profiles/show.html.erb` | `sm:max-w-lg` | `sm:max-w-screen-2xl` |

**Manter sem alteração:**
- `app/views/sessions/new.html.erb` — `max-w-md` (login)
- `app/views/passwords/new.html.erb` e `edit.html.erb` — `max-w-md` (auth)
- `app/views/task_items/_modal_form.html.erb` — `max-w-lg` (modal)
- `app/components/task_card_component.html.erb` — `max-w-[240px] truncate` (célula da tabela, não container)

### Comportamento esperado

- **Mobile (< 640px):** `w-full` ativo, layout 100% da viewport — **sem mudança**
- **Tablet (640px–1535px):** `sm:max-w-screen-2xl` permite usar até 1536px, mas em telas menores que isso o container já é < 1536px naturalmente — efetivamente full width
- **Desktop wide (1536px+):** Container chega a 1536px com margem automática centralizada — máximo aproveitamento sem perder legibilidade em monitores 4K

---

## Arquivos a Modificar

10 arquivos de view — todos com substituição cirúrgica de classes Tailwind. Sem alteração em controllers, models, JS ou specs.

---

## Testes

- [ ] Specs existentes (`mobile_first_spec`, `accessibility_spec`, todos os request/system specs) continuam passando — **sem regressão**
- [ ] Validação manual via Playwright em viewports:
  - [ ] 375px (mobile) — todos os elementos ocupam 100% sem overflow
  - [ ] 768px (tablet) — layout fluido sem quebras
  - [ ] 1280px (laptop) — sem mudança visual significativa (já era max-w-7xl ≈ 1280px)
  - [ ] 1920px (desktop) — dashboard e listagens aproveitam ~1536px de largura
  - [ ] 2560px (ultra-wide) — container centralizado em 1536px com margens iguais

---

## Observações

- **Por que `max-w-screen-2xl` (1536px) e não `w-full` puro?** Em monitores 4K (3840px+), uma listagem 100% full width fica visualmente quebrada — linhas de tabela tão largas que o olho perde a referência horizontal. 1536px é o limite que mantém densidade alta sem sacrificar legibilidade.
- **Login mantém `max-w-md`** porque telas de autenticação centralizadas são padrão consolidado (Google, GitHub, etc) — usuário não precisa de "largura" para preencher 2 campos.
- **Modal `max-w-lg` mantido** porque modais ultra-largos quebram o foco no formulário.

---

## Estimativa

**1 story point** (~1h) — 10 arquivos com substituição de classe Tailwind + validação visual Playwright. Sem mudanças de lógica, sem migrations, sem novos specs.
