# DM-010 — Observabilidade & UX Polish

**Tipo:** Transversal / Operações & Experiência
**Epic associado:** 11
**Stories:** 4
**Status:** ready-for-dev
**Data:** 2026-05-26

---

## Propósito

Com produção estabilizada e usuários começando a entrar, este domínio entrega **capacidade de entender como o sistema é usado** e **polir experiência** baseada em dados objetivos:

1. **Logs estruturados** — substituir linhas humanas por JSON queryável
2. **Healthcheck dedicado** — endpoint `/up` customizado com checks de DB e jobs
3. **Analytics de produto** — drop-off no onboarding, feature usage
4. **Acessibilidade WCAG nível AA** — auditoria + ajustes para o nível superior

---

## Stories

| # | Título | Prioridade | SP |
|---|--------|------------|----|
| 11.1 | Logs estruturados com Lograge | MEDIUM | 1 |
| 11.2 | Healthcheck endpoint `/up` customizado | MEDIUM | 1 |
| 11.3 | Analytics de produto (Plausible ou PostHog) | HIGH | 2 |
| 11.4 | Acessibilidade WCAG nível AA completa | MEDIUM | 2 |

**Total: 6 SP (~8-10h)**

---

## Dependências

- DM-008 (multi-tenant em produção, base para analytics)
- DM-009 (hardening — ENV vars validadas no boot)
- Conta no provider de analytics escolhido (Plausible $9/mês, PostHog free tier generoso)

---

## Não-objetivos

- APM completo (New Relic, Datadog) — fora de escopo, alto custo
- Error tracking (Sentry, Honeybadger) — desejável mas separado (Story 11.5?)
- A/B testing — prematuro com 1-5 usuários
- WCAG nível AAA — esforço desproporcional ao retorno

---

## Riscos

| Risco | Mitigação |
|-------|-----------|
| Analytics intrusivo demais (cookie banners obrigatórios na UE) | Escolher Plausible (cookie-less, GDPR-friendly out of the box) |
| Lograge quebrar logs do Railway dashboard | Configurar payload conservador; testar em staging primeiro |
| Auditoria WCAG AA encontrar muito mais que esperado | Limitar escopo a 3 fluxos principais: login, onboarding, lançamento de horas |
