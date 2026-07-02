# Cronos POC — Índice de Domínios (Final)

**Data:** 2026-05-26
**Status:** Projeto entregue, em produção

---

## Visão Geral

O Cronos POC é organizado em **8 domínios** que cobrem desde infraestrutura técnica até experiência do usuário final, distribuídos em **9 Epics** com total de **74 stories**, todas entregues.

---

## Mapa de Domínios

| Código | Domínio | Tipo | Epics | Stories | Status |
|--------|---------|------|-------|---------|--------|
| **DM-001** | Autenticação & Infraestrutura | Core | 1, 9 | 11 | ✅ done |
| **DM-002** | Gestão de Empresas | Core | 2 | 5 | ✅ done |
| **DM-003** | Gestão de Projetos | Core | 3 | 5 | ✅ done |
| **DM-004** | Registro de Tempo (Tasks/TaskItems) | Core / Principal | 4, 7 | 18 | ✅ done |
| **DM-005** | Visualização & Totalizadores | Consumo / Apresentação | 5 | 23 | ✅ done |
| **DM-006** | Filtros Dinâmicos | Consumo / Apresentação | 6 | 4 | ✅ done |
| **DM-007** | Experiência Mobile & Responsividade | Transversal | 8 | 5 | ✅ done |
| **DM-008** | Multi-Tenancy & Google OAuth | Transversal / Segurança & SaaS | 9 | 3 | ✅ done |
| **DM-009** | Hardening de Produção | Transversal / Segurança & Ops | 10 | 4 | 🔵 ready-for-dev |
| **DM-010** | Observabilidade & UX Polish | Transversal / Ops & Experiência | 11 | 4 | 🔵 ready-for-dev |
| **DM-011** | Validação com Usuários Reais | Discovery / Product | 12 | 3 | 🔵 ready-for-dev |

**Total: 74 stories entregues + 11 stories planejadas (roadmap)**

---

## Dependências entre domínios

```
DM-001 (auth, infra)
   │
   ├─→ DM-002 (companies)
   │      │
   │      ├─→ DM-003 (projects)
   │      │      │
   │      │      └─→ DM-004 (tasks/task_items)
   │      │             │
   │      │             ├─→ DM-005 (dashboard/totalizadores)
   │      │             │
   │      │             └─→ DM-006 (filtros)
   │      │
   │      └─→ DM-007 (mobile-first, transversal a tudo)
   │
   └─→ DM-008 (multi-tenancy + OAuth, transversal a tudo)
```

DM-008 foi entregue por último mas afeta retroativamente todos os domínios anteriores (refactor de scoping em controllers, factories, specs).

---

## Domínios em detalhe

### DM-001 — Autenticação & Infraestrutura (11 stories)
**Responsabilidades:** setup Rails, Docker, RSpec, CI, autenticação por email/senha, validações tripla camada, perfil de usuário (alteração de senha).

**Marcos:**
- Story 1.1 — Inicializar Rails
- Story 1.8 — UI base com Tailwind dark
- Story 1.10 — Validações client + server
- Story 1.11 — Alteração de senha

### DM-002 — Gestão de Empresas (5 stories)
CRUD de Companies com hourly_rate e soft delete (`active` flag). Validação de unicidade de nome por user.

### DM-003 — Gestão de Projetos (5 stories)
Projects vinculados a Company. Validação de cascata (project não pode pertencer a company de outro user, nem company desativada).

### DM-004 — Registro de Tempo (18 stories — maior do projeto)
**Coração do sistema.** Tasks (código, nome, horas estimadas) + TaskItems (lançamentos com start_time/end_time/work_date). Status automático (pending → completed → delivered), snapshots financeiros, edit/destroy modal, reabertura controlada.

**Marcos:**
- 4.2 — Model Task com validação tripla camada
- 4.3 — Model TaskItem com cálculos automáticos
- 4.15 — Persistir hourly_rate/value como snapshot
- 4.16 — Bug fix combobox Projeto disabled em edit
- 4.17 — Form de edição completo com tabs
- 4.18 — Reabrir tarefa entregue

### DM-005 — Visualização & Totalizadores (23 stories — mais ágil)
**Dashboard rico.** 9 KPIs em grid 3×3, lista de tasks do mês, modal de TaskItems, Turbo Streams para tudo, tela de resumo diário, ajustes visuais cirúrgicos (ícones verde/amarelo).

**Marcos:**
- 5.4 — Totalizadores por empresa no mês
- 5.10 — 6 KPIs no dashboard (qtde + horas + valor × dia/mês)
- 5.11 — Botão entregar task com Turbo Stream
- 5.19 — KPIs de entregas no mês
- 5.22 — Tela de resumo diário com filtro de mês
- 5.23/5.24 — Padronização visual de ícones

### DM-006 — Filtros Dinâmicos (4 stories)
Filtros por empresa, projeto, status e período com Turbo Frame + Stimulus debounce. Recalcula totalizadores conforme filtros ativos.

### DM-007 — Experiência Mobile & Responsividade (5 stories)
Mobile-first com breakpoints Tailwind sm/md/lg, viewports testadas, acessibilidade WCAG nível A, full-width layout (sem cap rígido).

### DM-008 — Multi-Tenancy & Google OAuth (3 stories — maior impacto)
**Última e mais transversal entrega.** OAuth Google coexistindo com email/senha, multi-tenancy real (`user_id` em todas as entidades + scoping defense-in-depth), onboarding de 3 passos para novos usuários.

**Marcos:**
- 9.1 — OAuth Google (lado a lado com email/senha)
- 9.2 — Multi-tenancy isolamento (8 SP, maior story do projeto)
- 9.3 — Onboarding primeiro acesso

---

## Métricas finais

| Métrica | Valor |
|---------|-------|
| Domínios | 8 |
| Epics | 9 |
| Stories totais | 74 |
| Stories críticas | 18 |
| Stories high | 32 |
| Stories medium | 18 |
| Stories low | 6 |
| Story points totais | ~120 SP (estimados) |
| QA findings catalogados | 72 |
| Suite de specs | 1.120 examples |
| Cobertura | 100% line |

---

## Status final por domínio

```
DM-001 ████████████████████ 100% (11/11)
DM-002 ████████████████████ 100% (5/5)
DM-003 ████████████████████ 100% (5/5)
DM-004 ████████████████████ 100% (18/18)
DM-005 ████████████████████ 100% (23/23)
DM-006 ████████████████████ 100% (4/4)
DM-007 ████████████████████ 100% (5/5)
DM-008 ████████████████████ 100% (3/3)
────────────────────────────────────
TOTAL  ████████████████████ 100% (74/74)
```
