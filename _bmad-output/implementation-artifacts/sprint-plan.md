---
workflowType: 'sprint-planning'
workflow: 'final'
project_name: 'cronos-poc'
date: '2026-05-26'
status: 'complete'
---

# Sprint Plan — Cronos POC (Consolidado Final)

**Status:** Todos os sprints concluídos. Projeto entregue em produção.
**Data:** 2026-05-26

---

## Visão geral

O projeto foi executado em **9 sprints (1 por Epic)**, com **74 stories** entregues ao longo de ~5 meses de desenvolvimento. Cada sprint correspondeu a um domínio funcional completo.

---

## Sprint 1 — Setup & Autenticação (Epic 1, DM-001)
**Stories:** 11 | **Status:** ✅ done

| Story | Descrição | Status |
|-------|-----------|--------|
| 1.1 | Inicializar Rails | ✅ |
| 1.2 | Docker + docker-compose | ✅ |
| 1.3 | RSpec + FactoryBot + Faker | ✅ |
| 1.4 | Tailwind CSS v4 | ✅ |
| 1.5 | Auth com has_secure_password | ✅ |
| 1.6 | Disable signup + seed admin | ✅ |
| 1.7 | Rails credentials | ✅ |
| 1.8 | UI base dark theme | ✅ |
| 1.9 | Menu de navegação | ✅ |
| 1.10 | Validações tripla camada | ✅ |
| 1.11 | Alterar senha no perfil | ✅ |

---

## Sprint 2 — Gestão de Empresas (Epic 2, DM-002)
**Stories:** 5 | **Status:** ✅ done

CRUD completo de Companies com hourly_rate e soft delete.

---

## Sprint 3 — Gestão de Projetos (Epic 3, DM-003)
**Stories:** 5 | **Status:** ✅ done

Projects vinculados a Company com validação de cascata + Stimulus project selector dinâmico.

---

## Sprint 4 — Task Management (Epic 4, DM-004)
**Stories:** 11 | **Status:** ✅ done

Coração funcional: Tasks + TaskItems com cálculos automáticos, status pending/completed/delivered, snapshots de hourly_rate/value.

**Marcos:**
- 4.2/4.3 — Models com validação tripla camada
- 4.4 — Lógica de status automático
- 4.15 — Snapshots financeiros (auditoria imutável)

---

## Sprint 5 — Visualização & Dashboard (Epic 5, DM-005)
**Stories:** 23 | **Status:** ✅ done — **maior sprint do projeto**

Dashboard com 9 KPIs em grid 3×3, lista de tasks do mês, modais Turbo Frame, Turbo Streams para tudo, tela de resumo diário, ajustes visuais cirúrgicos.

**Highlights:**
- 5.10 — Expansão de 3 para 6 KPIs
- 5.14 — Migração SSE → ActionCable broadcast
- 5.19 — 3 novos KPIs de entregas
- 5.22 — Tela de resumo diário com filtro de mês

---

## Sprint 6 — Filtros Dinâmicos (Epic 6, DM-006)
**Stories:** 4 | **Status:** ✅ done

Filtros por empresa, projeto, status e período com debounce Stimulus + Turbo Frame.

---

## Sprint 7 — Edição & Correção (Epic 7, DM-004)
**Stories:** 6 (incluindo 4.16, 4.17, 4.18 que migraram de planejamento) | **Status:** ✅ done

Edit/Update de Tasks/TaskItems + form completo em tabs + reabrir tarefa entregue.

**Marcos:**
- 4.17 — Form de edição com 3 tabs (Dados/Horas/Financeiro)
- 4.18 — Reabrir tarefa entregue com modal de confirmação

---

## Sprint 8 — Mobile & Acessibilidade (Epic 8, DM-007)
**Stories:** 5 | **Status:** ✅ done

Mobile-first, WCAG nível A, viewports testadas via Playwright em múltiplos dispositivos.

---

## Sprint 9 — Multi-Tenancy & OAuth (Epic 9, DM-008)
**Stories:** 3 | **Status:** ✅ done — **maior impacto arquitetural**

| Story | SP | QA findings aplicados |
|-------|----|-----------------------|
| 9.1 — Google OAuth (lado a lado) | 3 | 8 |
| 9.2 — Multi-tenancy isolamento | 8 | 22 (4 CRITICAL / 6 HIGH / 8 MEDIUM / 4 LOW) |
| 9.3 — Onboarding primeiro acesso | 2 | 18 (1 CRITICAL / 5 HIGH / 7 MEDIUM / 5 LOW) |

Esse sprint transformou o app de single-user em SaaS multi-tenant real.

---

## Métricas finais consolidadas

| Métrica | Valor |
|---------|-------|
| Sprints | 9 |
| Stories totais | 74 |
| Stories críticas | 18 |
| QA findings catalogados | 72 |
| Specs | 1.120 examples |
| Cobertura | 100% line |
| PRs mergeados | 167+ |
| Commits em master | 378 |
| Domínios entregues | 8/8 |

---

## Velocidade observada

- **Sprints maiores em stories:** 5 (23 stories) e 4 (11 stories)
- **Sprints maiores em impacto:** 9 (multi-tenancy + OAuth) e 4 (core models)
- **Sprint mais técnico:** 9 (22 QA findings só na 9.2)
- **Sprint mais ágil:** 6 (4 stories de filtros)

---

## Próximos sprints planejados

Todos com stories documentadas em `_bmad-output/implementation-artifacts/DM-XXX/`.

### Sprint 10 — Hardening de produção (DM-009, 4.5 SP)
- 10.1 — Rotacionar master.key + revogar credentials antigos (CRITICAL, 1 SP)
- 10.2 — Backup PostgreSQL automatizado (S3/B2/R2) (HIGH, 2 SP)
- 10.3 — Hook de verificação de ENVs no boot + remover password123 default (MEDIUM, 1 SP)
- 10.4 — Limpar/documentar arquivos Kamal abandonados (LOW, 0.5 SP)

### Sprint 11 — Observabilidade & UX Polish (DM-010, 6 SP)
- 11.1 — Logs estruturados com Lograge (MEDIUM, 1 SP)
- 11.2 — Healthcheck /up customizado (DB + queue + cache + migrations) (MEDIUM, 1 SP)
- 11.3 — Analytics de produto (Plausible ou PostHog, 7 eventos) (HIGH, 2 SP)
- 11.4 — Acessibilidade WCAG nível AA completa (MEDIUM, 2 SP)

### Sprint 12 — Validação com Usuários Reais (DM-011, 3 SP)
- 12.1 — Recrutar 3-5 pilotos + onboarding pessoal (HIGH, 1 SP)
- 12.2 — Entrevistas 30min + form quantitativo após 7-14 dias (HIGH, 1 SP)
- 12.3 — Síntese, categorização e decisão do próximo Epic 13 (HIGH, 1 SP)

### Sprint 13 — Disponibilidade sem Tarefa (DM-012, 7 SP)
- 13.1 — Model `IdlePeriod` + migration (user_id, start_time, end_time, hours calc) (MEDIUM, 1 SP)
- 13.2 — `IdlePeriodsController` (new modal, create, destroy) — padrão TaskItemsController (MEDIUM, 2 SP)
- 13.3 — KPI "Horas sem tarefa" no dashboard (dia/mês) + Turbo Stream via DashboardBroadcastJob (MEDIUM, 2 SP)
- 13.4 — Factories + specs completos (model, controller, request, dashboard KPI) (MEDIUM, 2 SP)

**Total planejado: 20.5 SP** distribuídos em 15 stories através de 4 sprints.

---

## Lições aprendidas (consolidadas na memória)

Top 10 lições aplicáveis a próximos projetos Rails:

1. **Specs com `include("X")` em string curta = falso positivo silencioso** — sempre asserir contexto específico
2. **`I18n.t` retorna a chave quando ausente** — validar `is_a?(Array)` antes de indexar
3. **`SUM(value)` com distinct duplica em multi-tabela** — preferir pluck + sum em Ruby
4. **Turbo Stream em form com `turbo: false` não engata** — mover link para fora do form
5. **`master.key` vazada exige rotação** — gitignore não basta; histórico continua acessível
6. **Multi-tenancy precisa defense-in-depth** — scope nos controllers + validator nos models + double-scope em nested + signed stream
7. **`Current.user` em SolidQueue exige reset garantido** — thread pollution entre jobs
8. **Playwright via Dashboard pega o que URL direta esconde** — bugs UX só aparecem no fluxo real
9. **Dependabot major bumps merecem review humano** — auto-merge só para patch/minor
10. **100% cobertura como CI gate funciona** — desde que arquivos não-testáveis sejam filtrados

---

## Histórico de retrospectivas

| Epic | Retrospectiva | Notas |
|------|---------------|-------|
| Epic 4 | ✅ done (2026-01-26) | 161 testes passando, zero blockers |
| Epic 9 | ✅ done (2026-05-26) | Encerramento do projeto, em produção |
| Geral | ✅ done (2026-05-26) | Retrospectiva final consolidada |
