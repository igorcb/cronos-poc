# DM-009 — Hardening de Produção

**Tipo:** Transversal / Segurança & Operações
**Epic associado:** 10
**Stories:** 4
**Status:** ready-for-dev
**Data:** 2026-05-26

---

## Propósito

Com o app em produção no Railway e exposição a usuários reais via OAuth self-service, este domínio trata de **resiliência operacional e segurança**. Foco em três frentes:

1. **Credentials hygiene** — rotacionar `master.key` (atual está pública no histórico do git)
2. **Backup** — proteger PostgreSQL contra falha do provider
3. **Fail fast** — boot do app valida presença de ENVs críticas

---

## Stories

| # | Título | Prioridade | SP |
|---|--------|------------|----|
| 10.1 | Rotacionar `master.key` e revogar credentials antigos | CRITICAL | 1 |
| 10.2 | Backup PostgreSQL automatizado (off-provider) | HIGH | 2 |
| 10.3 | Hook de verificação de ENVs no boot da aplicação | MEDIUM | 1 |
| 10.4 | Limpar ou documentar arquivos Kamal abandonados | LOW | 0.5 |

**Total: 4.5 SP (~6-8h)**

---

## Dependências

- DM-008 (multi-tenant, em produção)
- Acesso ao Railway dashboard (para gerenciar ENVs e Postgres)
- Conta S3/Backblaze para backup (provider escolhido durante implementação)

---

## Não-objetivos

- Migrar de Railway para outro provider
- Implementar HA / multi-region
- Disaster recovery completo com RTO/RPO formais

---

## Riscos

| Risco | Mitigação |
|-------|-----------|
| Rotacionar master.key sem ter encryptados arquivos atuais | Backup do `credentials.yml.enc` antigo antes; verificar se há dados sensíveis dentro |
| Backup escrevendo em S3 sem credenciais válidas | Story 10.3 (verificação de ENVs no boot) reduz risco |
| Quebrar deploy ao trocar master.key | Atualizar `RAILS_MASTER_KEY` no Railway ANTES de fazer push |
