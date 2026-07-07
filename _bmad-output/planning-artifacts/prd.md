---
workflowType: 'prd'
workflow: 'final'
project_name: 'cronos-poc'
user_name: 'Igor'
date: '2026-05-26'
status: 'shipped'
---

# Product Requirements Document — Cronos POC

**Autor:** Igor Batista
**Data inicial:** 2025-12-26
**Data desta versão:** 2026-05-26
**Status:** Shipped (em produção no Railway)

---

## 1. Executive Summary

O **Cronos POC** é um SaaS web de timesheet (controle de horas trabalhadas) **multi-tenant**, hoje em produção, criado para resolver a dificuldade de profissionais que prestam serviço a múltiplas empresas em manter registros confiáveis, auditáveis e financeiramente rastreáveis das horas trabalhadas e do valor faturado por empresa/projeto/tarefa.

**Estado atual (2026-05-26):**
- App em produção em `https://loyal-truth-production-d622.up.railway.app`
- Multi-tenancy real: cada usuário possui suas próprias Companies/Projects/Tasks/TaskItems isoladas
- Login via **Google OAuth** (one-click, self-service) e/ou **email/senha** (legado, ainda funcional)
- Onboarding guiado de 3 passos para novos usuários
- 1.120 specs, 100% cobertura de linha enforced no CI

---

## 2. Problema

Profissionais que atuam para várias empresas e projetos:
1. Perdem registros precisos do tempo trabalhado por tarefa
2. Não conseguem auditar o valor financeiro por entrega (rate × horas)
3. Misturam controle em planilhas, cadernos e apps de uso geral — sem trilha histórica imutável
4. Não têm visão consolidada diária/mensal sem reconciliação manual

---

## 3. Personas

### Igor (proprietário do MVP)
- Desenvolvedor solo prestando serviço a 2–3 empresas em paralelo
- Precisa registrar lançamentos diários, faturar mensalmente, validar entregas
- Vai abrir o sistema para outros profissionais self-service (multi-tenant)

### Novo usuário SaaS (a partir de Epic 9)
- Outro freelancer/PJ que descobre o produto, cadastra conta via Google
- Espera ver um onboarding claro (3 passos: criar Empresa → Projeto → Tarefa)
- Quer dados privados, isolados de outros usuários

---

## 4. Jornadas-chave

### Jornada 1 — Onboarding self-service (novo usuário)
1. Acessa URL pública → tela de login
2. Clica em "Entrar com Google" → autoriza
3. Cai em dashboard de onboarding (Passo 1 destacado, 2 e 3 trancados)
4. Cria Empresa → redirect automático para Passo 2 (criar Projeto)
5. Cria Projeto → redirect para Passo 3 (criar Tarefa)
6. Cria primeira Tarefa → flash "Configuração concluída!" → dashboard normal

### Jornada 2 — Lançamento de horas (uso diário)
1. Dashboard mostra KPIs do dia/mês/entregue + lista de tarefas do mês
2. Clica em tarefa → modal lateral abre com histórico de lançamentos
3. Adiciona lançamento (start_time, end_time, work_date) → horas e valor calculados automaticamente
4. KPIs do dashboard atualizam via Turbo Stream em tempo real
5. Sem reload, fluxo otimizado mobile-first

### Jornada 3 — Edição/correção de lançamentos
1. Modal de histórico permite editar/excluir TaskItem individual
2. Excluir TaskItem recalcula `validated_hours` da Task e atualiza Turbo Streams
3. Validações impedem TaskItems com overflow de horas estimadas (alerta de excedente)

### Jornada 4 — Entrega e reabertura
1. Tarefa atinge horas estimadas → status passa a `completed` automaticamente
2. Botão check no dashboard → modal de confirmação → status `delivered`
3. Snapshot imutável de `hourly_rate` e `delivered_value` na Task
4. Banner no `/tasks/:id/edit` permite **reabrir** delivered → completed (limpa snapshot)

### Jornada 5 — Conferência mensal e faturamento
1. Tela `/resumo-diario` mostra tabela Data | Qtde | Horas | Valor com filtro por mês
2. KPIs no topo: cards no mês, horas no mês, valor no mês
3. Igor concilia contra planilha externa ou usa para fechar fatura

---

## 5. Capacidades MVP entregues

| Capacidade | Detalhes |
|------------|----------|
| **Autenticação dual** | Login email/senha + Google OAuth coexistindo |
| **Multi-tenant real** | `user_id` em Companies/Projects/Tasks/TaskItems; scoping em todos os controllers |
| **CRUD de Companies** | Nome, hourly_rate, active flag (soft delete) |
| **CRUD de Projects** | Vinculados a Company, validação de cascata |
| **CRUD de Tasks** | Código + nome + estimated_hours + start_date + end_date + status + notes |
| **Lançamentos (TaskItems)** | start_time/end_time/work_date com cálculo automático de hours_worked e value |
| **Snapshots imutáveis** | `task_items.hourly_rate/value` no lançamento; `tasks.hourly_rate/delivered_value` na entrega |
| **Status automático** | pending → completed → delivered baseado em horas validadas e ação manual |
| **Reabertura controlada** | Modal de confirmação para reverter delivered → completed |
| **Dashboard com 9 KPIs** | Tasks/Horas/Valor (Hoje/Mês) + Entregas/Horas/Valor entregues + Média por entrega |
| **Lista de tarefas do mês** | Ordenada, com KPIs por linha e ações inline |
| **Resumo diário** | Tabela Data/Qtde/Horas/Valor com filtro de mês |
| **Filtros dinâmicos** | Empresa, projeto, status, período (com Turbo Frame) |
| **Turbo Streams** | KPIs e listas atualizam sem reload (multi-tenant via stream assinado `[user, :dashboard]`) |
| **Mobile-first** | Layout full-width, breakpoints sm/md/lg, touch-friendly |
| **Onboarding** | 3 passos para novo usuário com 0 Companies |
| **Acessibilidade** | WCAG nível A, navegação por teclado, ARIA labels |

---

## 6. Não-objetivos do MVP

- ❌ Tour interativo / wizard de 5+ passos no onboarding
- ❌ Faturamento integrado a sistemas fiscais (NF-e, etc.)
- ❌ App mobile nativo (PWA é satisfatório)
- ❌ Multi-idioma (apenas pt-BR)
- ❌ Times/colaboração entre users (apenas single-user multi-tenant)
- ❌ Importação CSV/Excel de lançamentos
- ❌ Analytics de drop-off de onboarding (fica para Epic 11 sugerido)

---

## 7. Métricas de sucesso

| Métrica | Alvo | Status |
|---------|------|--------|
| Cobertura de testes | 100% line | ✅ Atingido |
| Suite de specs | 1.000+ examples | ✅ 1.120 |
| Multi-tenancy isolado (Playwright cross-tenant) | 404 em recurso de outro user | ✅ Validado |
| Onboarding funcional ponta-a-ponta | Login → 3 steps → dashboard | ✅ Validado |
| Deploy em produção | URL pública acessível | ✅ Railway |
| Tempo médio até primeira Task (novo user) | < 5 min | Não medido (sem analytics) |

---

## 8. Constraints e riscos

### Constraints técnicos
- Rails 8.1, Ruby 3.4
- PostgreSQL como único banco
- Tailwind v4 (sem `max-w-screen-2xl`, usar arbitrary values)
- Sem React/frontend separado — Hotwire (Turbo + Stimulus) apenas

### Riscos conhecidos
- **🔴 `master.key` vazada no histórico do git** (commits `f2afcb5`, `dab3c07`) — exige rotação antes de qualquer secret real em `credentials.yml.enc`
- **🟡 Dependência única do Railway para persistência** — backup PostgreSQL automatizado ainda pendente
- **🟡 Sem observabilidade estruturada** — logs limitados ao retentor padrão do Railway

---

## 9. Roadmap pós-MVP (sugerido)

### Epic 10 — Hardening de produção
- Rotacionar master.key + revogar credentials antigos
- Backup PostgreSQL automatizado (S3/Backblaze, dump diário)
- Hook de verificação de ENVs no boot

### Epic 11 — Observabilidade & UX polish
- Analytics de drop-off no onboarding (Plausible/PostHog)
- Lograge + logs estruturados
- Acessibilidade WCAG AA completa

### Epic 12 — Validação com usuários reais
- Convidar 3-5 usuários piloto
- Medir uso real, deixar próximas features emergirem do uso

---

## 10. Histórico de versões

| Versão | Data | Mudança |
|--------|------|---------|
| 1.0 | 2025-12-26 | PRD inicial — 8 epics planejados |
| 1.1 | 2026-04-21 | Adição da lista de tarefas no dashboard |
| 1.2 | 2026-05-07 | Persistência de hourly_rate/value (snapshots) |
| 1.3 | 2026-05-15 | Epic 9 (Multi-tenancy + OAuth) planejado |
| **2.0** | **2026-05-26** | **PRD final — projeto entregue, 9 epics, 74 stories, em produção** |
