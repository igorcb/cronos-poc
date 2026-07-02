# Story 10.1: Rotacionar master.key e Revogar Credentials Antigos

**Status:** ready-for-dev
**Domínio:** DM-009-hardening-producao
**Epic:** Epic 10 — Hardening de Produção
**Story ID:** 10.1
**Prioridade:** CRITICAL
**Estimativa:** 1 SP

---

## Contexto

A `config/master.key` original do projeto (valor `0a3a8915e3b76731cf80e14bba5ab92d`) foi **commitada nos commits `f2afcb5` e `dab3c07`** no início do projeto. Embora o arquivo esteja hoje no `.gitignore`, **continua acessível no histórico público do GitHub**.

Hoje isso não tem efeito prático porque `credentials.yml.enc` não armazena segredos relevantes. **MAS** o app já está em produção e qualquer secret adicionado a `credentials.yml.enc` daqui em diante seria descriptografável por qualquer pessoa que clone o repo.

Esta story rotaciona a chave **antes** de adicionar qualquer secret real.

---

## História do Usuário

**Como** operador do Cronos POC em produção,
**Quero** rotacionar a `master.key` e ter `credentials.yml.enc` limpo,
**Para** poder armazenar secrets reais (API keys, tokens) sem risco de vazamento.

---

## Critérios de Aceite

### AC1 — Auditoria prévia
- [ ] **AC1.1:** Documentar conteúdo atual de `credentials.yml.enc` (deve estar vazio ou só ter `secret_key_base`)
- [ ] **AC1.2:** Confirmar que nenhuma API key/token real está dentro

### AC2 — Rotação local
- [ ] **AC2.1:** Backup local: `cp config/master.key /tmp/master.key.OLD-2026-05-26`
- [ ] **AC2.2:** Deletar `config/master.key` e `config/credentials.yml.enc` locais
- [ ] **AC2.3:** Gerar nova chave + arquivo: `EDITOR=vim bin/rails credentials:edit`
- [ ] **AC2.4:** Confirmar que nova chave é diferente da antiga

### AC3 — Atualização em produção
- [ ] **AC3.1:** Acessar Railway dashboard → Variables
- [ ] **AC3.2:** Atualizar `RAILS_MASTER_KEY` com novo valor
- [ ] **AC3.3:** Verificar que o deploy reinicia sem erro

### AC4 — Commit + push
- [ ] **AC4.1:** Commit do novo `credentials.yml.enc`
- [ ] **AC4.2:** PR + merge
- [ ] **AC4.3:** Confirmar deploy automático em Railway sucesso

### AC5 — Validação
- [ ] **AC5.1:** Login no app em produção funciona
- [ ] **AC5.2:** Multi-tenancy funciona (criar nova conta + isolamento)
- [ ] **AC5.3:** Não há erro de decrypt em logs

---

## Análise Técnica

### Sequência segura

```bash
# 1. Backup da chave antiga (caso precise rollback)
cp config/master.key /tmp/master.key.OLD-2026-05-26

# 2. Conferir conteúdo dos credentials antes
EDITOR=cat bin/rails credentials:show  # ou credentials:edit + leitura

# 3. Apagar arquivos locais
rm config/master.key config/credentials.yml.enc

# 4. Gerar nova chave + criar credentials vazio
EDITOR=vim bin/rails credentials:edit
# Salva e sai (cria os 2 arquivos com nova chave)

# 5. Copiar nova chave para clipboard
cat config/master.key

# 6. Atualizar Railway ANTES de push (senão deploy quebra)
# Railway dashboard → Variables → RAILS_MASTER_KEY = (cole valor)

# 7. Commit do novo credentials.yml.enc
git add config/credentials.yml.enc
git commit -m "chore(security): rotacionar master.key e credentials"
git push
```

### Importante: ordem crítica
**Atualizar `RAILS_MASTER_KEY` no Railway ANTES do push.** Se o push for primeiro:
- Deploy quebra porque key antiga não decripta novo enc
- App fica down até atualizar ENV
- Risco baixo (rollback é trivial), mas evitável

---

## Arquivos a Modificar

| Arquivo | Ação |
|---------|------|
| `config/master.key` | Deletar e regenerar |
| `config/credentials.yml.enc` | Deletar e regenerar |

---

## Testes

- [ ] Login email/senha pós-rotação
- [ ] Login Google OAuth pós-rotação
- [ ] Criar Task em produção (smoke test)
- [ ] Logs Railway sem `ActiveSupport::MessageEncryptor::InvalidMessage`

---

## Observações

- **Histórico do git permanece comprometido** — quem já clonou pode usar a chave antiga até para descriptografar `credentials.yml.enc` antigos baixados. Mas como a partir desta rotação tudo é nova chave, o risco é apenas com versões antigas (que já estão obsoletas).
- Para limpeza completa do histórico seria preciso `git filter-repo` — fora de escopo desta story (operação destrutiva, exige força push, invalida clones). Documentar como follow-up opcional.
- **Não rotacionar credentials de Google OAuth nesta story** — fica em 10.x separada se necessário.
