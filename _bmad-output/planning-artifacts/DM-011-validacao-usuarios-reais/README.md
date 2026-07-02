# DM-011 — Validação com Usuários Reais

**Tipo:** Discovery / Product
**Epic associado:** 12
**Stories:** 3
**Status:** ready-for-dev (depende de 11.3 analytics)
**Data:** 2026-05-26

---

## Propósito

Sair do desenvolvimento solo e **submeter o Cronos POC ao uso real**. Sem usuários reais, todo backlog é palpite. Este domínio é o mais difícil de todos: muito menos código, muito mais conversa e medição.

Princípio orientador: *"Ship the smallest thing that validates the assumption"* — mesma frase que guiou o projeto desde o início, agora aplicada ao produto em si, não a uma feature.

---

## Stories

| # | Título | Prioridade | SP |
|---|--------|------------|----|
| 12.1 | Recrutar 3-5 usuários piloto e onboarding pessoal | HIGH | 1 |
| 12.2 | Coletar feedback estruturado (entrevistas + form) | HIGH | 1 |
| 12.3 | Síntese e priorização do próximo Epic baseada em uso real | HIGH | 1 |

**Total: 3 SP (efeito multiplicador no roadmap futuro)**

---

## Dependências

- DM-008 (multi-tenancy estável — usuários reais não podem ver dados uns dos outros)
- DM-009 (master.key rotacionada — antes de expor a estranhos)
- **DM-010 (analytics)** — sem isso, decisões serão por anedota, não por dados

---

## Não-objetivos

- Implementar features pedidas pelos usuários piloto (vão virar Epic separado)
- Marketing / aquisição em escala (3-5 pessoas, não 100)
- Cobrança (manter free durante validação)

---

## Princípios

1. **Recrutar pessoas que têm o problema** (freelas, PJs com múltiplas empresas), não amigos por simpatia
2. **Não defender o produto durante entrevista** — escutar críticas em silêncio
3. **Buscar surpresa** — features que ninguém usa, comportamentos inesperados, pedidos repetidos
4. **Decidir cortes** — toda feedback gera cardápio; só vira roadmap o que repete em 2+ usuários

---

## Riscos

| Risco | Mitigação |
|-------|-----------|
| Usuários piloto não voltam após o primeiro dia | Onboarding personalizado + check-in proativo na primeira semana |
| Feedback enviesado por simpatia | Misturar conhecidos com gente de comunidade externa |
| Bugs em produção quebram a experiência | DM-009 e DM-010 entregues antes do convite |
| Demanda por features prematuras de cobrança | Comunicar claramente "fase de validação, gratuito" |
