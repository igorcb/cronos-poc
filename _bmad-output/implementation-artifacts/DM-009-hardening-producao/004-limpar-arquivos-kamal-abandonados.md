# Story 10.4: Limpar ou Documentar Arquivos Kamal Abandonados

**Status:** ready-for-dev
**Domínio:** DM-009-hardening-producao
**Epic:** Epic 10 — Hardening de Produção
**Story ID:** 10.4
**Prioridade:** LOW
**Estimativa:** 0.5 SP

---

## Contexto

O projeto tem **dois sistemas de deploy declarados no repo**:

1. **Railway** (ativo, em produção) — `.railway.json`, `RAILWAY_DEPLOY.md`, `scripts/deploy-railway.sh`
2. **Kamal** (inerte, código morto) — `config/deploy.yml` com placeholders padrão (`192.168.0.1`, `image: app`, `localhost:5555`), `.kamal/secrets` template

A presença dos dois confunde:
- Auditor de segurança (já comprovado: PM achou que não havia produção)
- Novo dev no projeto
- Ferramentas automatizadas que escaneiam por configuração de deploy

Esta story decide entre **(A) remover Kamal** ou **(B) documentar explicitamente como "não usado"**.

---

## História do Usuário

**Como** Igor mantendo o projeto solo,
**Quero** que o repo deixe claro qual sistema de deploy está em uso,
**Para** evitar confusão futura (minha ou de auditores) e simplificar decisões.

---

## Critérios de Aceite

### AC1 — Decisão arquitetural
- [ ] **AC1.1:** Decidir entre opção A (remover) ou opção B (documentar como abandonado)
- [ ] **AC1.2:** Registrar decisão em ADR no `architecture.md`

### AC2 — Opção A — Remover Kamal (recomendada)
Se escolhido:
- [ ] Remover `config/deploy.yml`
- [ ] Remover diretório `.kamal/` completo
- [ ] Remover `gem "kamal"` do Gemfile
- [ ] `bundle install` para atualizar Gemfile.lock
- [ ] Remover qualquer referência a Kamal em README/docs

### AC3 — Opção B — Documentar como abandonado
Se escolhido:
- [ ] Adicionar comentário no topo de `config/deploy.yml`:
  ```yaml
  # ⚠️ ARQUIVO NÃO USADO — Cronos POC faz deploy via Railway, não Kamal.
  # Mantido apenas como opção futura caso decida migrar para VPS.
  # Ver: RAILWAY_DEPLOY.md
  ```
- [ ] Adicionar nota similar em `.kamal/secrets`
- [ ] Documentar em `README.md` que Kamal não é o sistema ativo
- [ ] Considerar manter gem `kamal` no Gemfile **dentro de `group :production`** com flag `require: false`

### AC4 — README atualizado
- [ ] **AC4.1:** Seção "Deploy" no `README.md` aponta para `RAILWAY_DEPLOY.md` como única fonte da verdade
- [ ] **AC4.2:** Menciona Kamal só como "considerado e descartado" se Opção B

### AC5 — Sem regressão
- [ ] **AC5.1:** Deploy Railway continua funcionando após PR
- [ ] **AC5.2:** Suíte continua 100% passing

---

## Análise Técnica

### Recomendação

**Opção A — Remover.** Justificativas:

1. **Código morto causa confusão real** (comprovado nesta jornada)
2. **YAGNI** — se um dia migrar para VPS com Kamal, regenerar `config/deploy.yml` é trivial (`bin/kamal init`)
3. **Gemfile menor** — remove 1 dep + transitivas
4. **Repo mais limpo** — sinaliza claramente "Railway é o caminho"

### Itens a remover (Opção A)

```bash
git rm -r .kamal/
git rm config/deploy.yml
# Editar Gemfile:
# - gem "kamal", require: false
```

### Verificação pós-remoção

```bash
# Confirma que Kamal sumiu
find . -name "*kamal*" -not -path "*/node_modules/*" -not -path "*/.git/*"
# Esperado: vazio

# Confirma que bundle compila
docker exec cronos-poc-web-1 bundle install
```

---

## Arquivos a Modificar

### Opção A (remover)
| Arquivo | Ação |
|---------|------|
| `.kamal/` | Deletar diretório completo |
| `config/deploy.yml` | Deletar |
| `Gemfile` | Remover `gem "kamal"` |
| `Gemfile.lock` | Regenerar via bundle install |
| `README.md` | Atualizar seção Deploy |

### Opção B (documentar)
| Arquivo | Ação |
|---------|------|
| `config/deploy.yml` | Adicionar header de aviso |
| `.kamal/secrets` | Adicionar header de aviso |
| `README.md` | Mencionar Kamal como abandonado |

---

## Testes

- [ ] CI verde após PR
- [ ] Deploy Railway funcional
- [ ] Suite 1.120/1.120 passing

---

## Observações

- **Decisão entre A e B é do Igor.** Story documenta as duas para escolha durante implementação.
- Esta story é **pré-requisito leve para 10.1** — após rotacionar master.key, é boa hora de limpar o que não usa.
- Não impacta operação do sistema; só clarity do repo.
