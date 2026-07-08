---
workflowType: 'epics-and-stories'
workflow: 'final'
project_name: 'cronos-poc'
user_name: 'Igor'
date: '2026-05-26'
status: 'shipped'
totalEpics: 13
totalStories: 78
inputDocuments: ['prd.md', 'architecture.md', 'domain-index.md']
---

# Epics & Stories — Cronos POC (Final)

**Status:** 74/74 stories entregues — projeto em produção.

---

## Resumo dos Epics

| # | Epic | Domínio | Stories | Status |
|---|------|---------|---------|--------|
| 1 | Setup & Autenticação | DM-001 | 10 | ✅ done |
| 2 | Gestão de Empresas | DM-002 | 5 | ✅ done |
| 3 | Gestão de Projetos | DM-003 | 5 | ✅ done |
| 4 | Task Management | DM-004 | 13 | ✅ done |
| 5 | Visualização & Dashboard | DM-005 | 23 | ✅ done |
| 6 | Filtros Dinâmicos | DM-006 | 4 | ✅ done |
| 7 | Edição & Correção | DM-004 (Epic 7) | 5 | ✅ done |
| 8 | Mobile & Acessibilidade | DM-007 | 5 | ✅ done |
| 9 | Multi-Tenancy & OAuth | DM-008 | 3 | ✅ done |
| 10 | Hardening de Produção | DM-009 | 4 | 🔵 ready-for-dev |
| 11 | Observabilidade & UX Polish | DM-010 | 4 | 🔵 ready-for-dev |
| 12 | Validação com Usuários Reais | DM-011 | 3 | 🔵 ready-for-dev |
| 13 | Disponibilidade sem Tarefa | DM-012 | 4 | 🔵 ready-for-dev |
| **TOTAL** | | | **89** | **74 done + 15 planejadas** |

---

## Epic 1 — Setup & Autenticação (DM-001)

- 1.1 Inicializar projeto Rails com starter template ✅
- 1.2 Configurar Docker e docker-compose ✅
- 1.3 Configurar RSpec, FactoryBot, Faker ✅
- 1.4 Configurar Tailwind CSS v4 ✅
- 1.5 Implementar autenticação com has_secure_password ✅
- 1.6 Desabilitar signup público + seed admin via ENV ✅
- 1.7 Configurar Rails credentials para secrets ✅
- 1.8 Implementar UI base com tema dark Tailwind ✅
- 1.9 Adicionar tarefas ao menu de navegação ✅
- 1.10 Validações tripla camada (DB + model + client) ✅
- 1.11 Alterar senha no perfil do usuário ✅

## Epic 2 — Gestão de Empresas (DM-002)

- 2.1 Model Company com validações ✅
- 2.2 CRUD index/new/create ✅
- 2.3 CRUD edit/update ✅
- 2.4 Soft delete via `active: false` ✅
- 2.5 Factories + specs completos ✅

## Epic 3 — Gestão de Projetos (DM-003)

- 3.1 Model Project com belongs_to Company ✅
- 3.2 CRUD com validação de cascata ✅
- 3.3 Project selector dinâmico (filtra por company) ✅
- 3.4 Soft delete e regras de cascata ✅
- 3.5 Factories + specs completos ✅

## Epic 4 — Task Management (DM-004)

- 4.1 Especificação Task Management ✅
- 4.2 Model Task com validações tripla camada ✅
- 4.3 Model TaskItem com cálculos automáticos ✅
- 4.4 Lógica de status automático (pending/completed/delivered) ✅
- 4.5 CRUD de Tasks — New/Create ✅
- 4.6 Project selector dinâmico com Stimulus ✅
- 4.7 Factories + 84 specs Task/TaskItem ✅
- 4.12 Simplificar Ações Rápidas no dashboard ✅
- 4.13 Campo código numérico na Task ✅
- 4.14 time_field para horas estimadas ✅
- 4.15 Gravar hourly_rate/value (snapshots) ✅

## Epic 5 — Visualização & Dashboard (DM-005)

- 5.1 Index de Tasks com eager loading ✅
- 5.2 ViewComponent para Task Card ✅
- 5.3 Totalizadores dinâmicos (total do dia) ✅
- 5.4 Totalizadores por empresa no mês ✅
- 5.5 Turbo Streams para atualização em tempo real ✅
- 5.6 Lista de tarefas do mês no dashboard ✅
- 5.7 Substituir Ações Rápidas por ícone Nova Tarefa ✅
- 5.8 Modal Nova Tarefa no dashboard ✅
- 5.9 Modal de lançamento de TaskItem ✅
- 5.10 Expandir KPIs (3 → 6 métricas) ✅
- 5.11 Botão Entregar Task no dashboard ✅
- 5.12 Remover blur do overlay modal ✅
- 5.13 Horas realizadas ao lado do estimado ✅
- 5.14 Migrar SSE para ActionCable broadcast ✅
- 5.15 Corrigir fuso horário Brasília ✅
- 5.16 Ajustes visuais (badges, KPIs, botões) ✅
- 5.17 Edição de TaskItem no modal ✅
- 5.18 Exclusão de TaskItem no modal ✅
- 5.19 Novos KPIs — Entregas/Horas/Valor entregues ✅
- 5.20 KPI Média por Entrega ✅
- 5.21 Coluna Valor (R$) na tabela ✅
- 5.22 Tela de Resumo Diário do Mês ✅
- 5.23 Padronizar ícone Valor Mês em verde ✅
- 5.24 Padronizar ícones do trio Hoje em amarelo ✅

## Epic 6 — Filtros Dinâmicos (DM-006)

- 6.1 Filtros por empresa e projeto ✅
- 6.2 Filtros por status e período ✅
- 6.3 Recalcular totalizadores conforme filtros ativos ✅
- 6.4 Stimulus controller para filtros com Turbo Frames ✅

## Epic 7 — Edição & Correção (DM-004 / Epic 7)

- 7.1 Edit/Update de Tasks e TaskItems ✅
- 7.2 Destroy de TaskItems com confirmação ✅
- 7.3 Specs de system para fluxo CRUD ✅
- 4.16 Bug fix combobox Projeto disabled em edit ✅
- 4.17 Form de edição completo (tabs) ✅
- 4.18 Reabrir tarefa entregue (delivered → completed) ✅

## Epic 8 — Mobile & Acessibilidade (DM-007)

- 8.1 Mobile-first com Tailwind breakpoints ✅
- 8.2 Otimizar TaskItem form para mobile ✅
- 8.3 Acessibilidade WCAG nível A ✅
- 8.4 Testar responsividade em múltiplos viewports ✅
- 8.5 Full-width layout em todas as páginas ✅

## Epic 9 — Multi-Tenancy & OAuth (DM-008)

- 9.1 Login via Google OAuth (lado a lado com email/senha) ✅
- 9.2 Multi-tenancy — isolamento de dados por usuário ✅
- 9.3 Onboarding — primeiro acesso (3 passos) ✅

## Epic 10 — Hardening de Produção (DM-009) 🔵 planejado

- 10.1 Rotacionar `master.key` e revogar credentials antigos (CRITICAL, 1 SP)
- 10.2 Backup PostgreSQL automatizado (off-provider) (HIGH, 2 SP)
- 10.3 Hook de verificação de ENVs no boot da aplicação (MEDIUM, 1 SP)
- 10.4 Limpar ou documentar arquivos Kamal abandonados (LOW, 0.5 SP)

**Total: 4.5 SP** | Foco: resiliência operacional e segurança pós-deploy

## Epic 11 — Observabilidade & UX Polish (DM-010) 🔵 planejado

- 11.1 Logs estruturados com Lograge (MEDIUM, 1 SP)
- 11.2 Healthcheck endpoint `/up` customizado (MEDIUM, 1 SP)
- 11.3 Analytics de produto (Plausible ou PostHog) (HIGH, 2 SP)
- 11.4 Acessibilidade WCAG nível AA completa (MEDIUM, 2 SP)

**Total: 6 SP** | Foco: entender uso real e polir experiência

## Epic 12 — Validação com Usuários Reais (DM-011) 🔵 planejado

- 12.1 Recrutar 3-5 usuários piloto e onboarding pessoal (HIGH, 1 SP)
- 12.2 Coletar feedback estruturado (entrevistas + form) (HIGH, 1 SP)
- 12.3 Síntese e priorização do próximo Epic baseada em uso real (HIGH, 1 SP)

**Total: 3 SP** | Foco: discovery — sair do desenvolvimento solo, extrair sinal real

## Epic 13 — Disponibilidade sem Tarefa (DM-012) 🔵 planejado

- 13.1 Model `IdlePeriod` + migration (user_id, start_time, end_time, hours calc) (MEDIUM, 1 SP)
- 13.2 `IdlePeriodsController` (new modal, create, destroy) — padrão TaskItemsController (MEDIUM, 2 SP)
- 13.3 KPI "Horas sem tarefa" no dashboard (dia/mês) + Turbo Stream via DashboardBroadcastJob (MEDIUM, 2 SP)
- 13.4 Factories + specs completos (model, controller, request, dashboard KPI) (MEDIUM, 2 SP)

**Total: 7 SP** | Foco: evidenciar disponibilidade sem tarefa para justificativa de horas contratuais (mín. 190h/mês)

---

## Top 10 stories de maior impacto

| Story | Impacto |
|-------|---------|
| **9.2 — Multi-tenancy** | Transformou single-user em SaaS multi-tenant |
| **4.15 — Snapshots financeiros** | Auditoria imutável de hourly_rate/value |
| **4.2 / 4.3 — Models Task/TaskItem** | Coração funcional do sistema |
| **5.10 — 6 KPIs dashboard** | Visão executiva do trabalho |
| **9.1 — Google OAuth** | Self-service de cadastro |
| **9.3 — Onboarding** | UX para novos usuários |
| **5.22 — Resumo diário** | Conferência mensal para faturamento |
| **5.5 — Turbo Streams** | UX em tempo real sem reload |
| **4.4 — Status automático** | Lógica de negócio core |
| **5.11 — Botão Entregar** | Workflow de fechamento de tarefa |

---

## Categorização

### Stories técnicas / refactor (4)
- 5.14 — Migrar SSE para ActionCable
- 5.15 — Corrigir fuso horário Brasília
- 4.16 — Fix combobox Projeto disabled
- 5.18 — Exclusão TaskItem (recalc validated_hours)

### Stories de polish visual (5)
- 5.12 — Remover blur overlay
- 5.16 — Ajustes visuais badges/KPIs
- 5.23 — Ícone Valor Mês em verde
- 5.24 — Ícones trio Hoje em amarelo
- 8.5 — Full-width layout

### Stories com QA round 2 aplicado (3)
- 9.1 — 8 findings aplicados
- 9.2 — 22 findings aplicados (4 CRITICAL/6 HIGH/8 MEDIUM/4 LOW)
- 9.3 — 18 findings aplicados (1 CRITICAL/5 HIGH/7 MEDIUM/5 LOW)
