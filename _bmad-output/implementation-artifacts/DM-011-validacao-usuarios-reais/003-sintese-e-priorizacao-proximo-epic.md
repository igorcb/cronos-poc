# Story 12.3: Síntese e Priorização do Próximo Epic Baseada em Uso Real

**Status:** ready-for-dev
**Domínio:** DM-011-validacao-usuarios-reais
**Epic:** Epic 12 — Validação com Usuários Reais
**Story ID:** 12.3
**Prioridade:** HIGH
**Estimativa:** 1 SP

---

## Contexto

Com Stories 12.1 e 12.2 entregues, há um corpus de dados: diário de bordo, 3-5 entrevistas, resultados de form, métricas de analytics da Story 11.3. Esta story **transforma esse material em decisão**: o que vira o próximo Epic? O que é descartado?

Sem síntese ativa, feedback vira pilha morta. Com método (categorização → triagem → escolha), vira roadmap.

---

## História do Usuário

**Como** Igor,
**Quero** transformar o feedback dos pilotos em um Epic priorizado e documentado,
**Para** que o próximo ciclo de desenvolvimento tenha justificativa baseada em uso real.

---

## Critérios de Aceite

### AC1 — Categorização dos findings
- [ ] **AC1.1:** Ler todas entrevistas + form + analytics (já documentados pelas Stories 12.1 e 12.2)
- [ ] **AC1.2:** Listar **todos os findings** em planilha/tabela (1 linha por finding)
- [ ] **AC1.3:** Categorizar por tipo:
  - **Bug** (algo quebrado)
  - **Friction** (UX confusa, fluxo travado)
  - **Missing feature** (algo desejado e não existe)
  - **Unused feature** (existe e ninguém usa)
  - **Performance** (lentidão percebida)
  - **Confusion** (não entendeu o que faz)

### AC2 — Triagem por frequência e impacto
- [ ] **AC2.1:** Marcar cada finding com:
  - **Frequência:** quantos pilotos mencionaram (1, 2, 3+)
  - **Severidade:** trivial / moderado / crítico
- [ ] **AC2.2:** **Regra de corte:** só vira candidato a roadmap o que aparece em **2+ usuários** (filtrar viés individual)
- [ ] **AC2.3:** Exceção: bugs CRITICAL aparecem em roadmap mesmo se 1 reportou (segurança)

### AC3 — Decisão do próximo Epic
- [ ] **AC3.1:** Identificar **tema dominante** entre os findings prioritários
- [ ] **AC3.2:** Esboçar Epic com base no tema (ex: se 4/5 pilotos pediram export CSV → "Epic 13 — Export & Integrações")
- [ ] **AC3.3:** Não tentar resolver tudo: escolher 1 Epic, deixar resto em backlog

### AC4 — Documentação
- [ ] **AC4.1:** Criar `_bmad-output/implementation-artifacts/DM-011-validacao-usuarios-reais/sintese-piloto.md` com:
  - Resumo executivo (1 página)
  - Tabela de findings categorizados
  - Top 5 findings priorizados (frequência × severidade)
  - Justificativa do Epic escolhido
  - Backlog descartado (com motivo)
- [ ] **AC4.2:** Atualizar `deferred-work.md` com findings que não viraram Epic mas merecem registro
- [ ] **AC4.3:** Esboçar o novo Epic em `_bmad-output/planning-artifacts/DM-012-XXX/README.md`

### AC5 — Comunicação
- [ ] **AC5.1:** Enviar mensagem para os pilotos:
  - Agradecer participação
  - Resumo do que ouviu
  - Avisar o que vai construir a seguir
  - Convidar para nova rodada quando o próximo Epic estiver pronto

### AC6 — Retrospectiva do Epic 12
- [ ] **AC6.1:** Curta retro: o que funcionou no processo de validação? O que mudar na próxima rodada?
- [ ] **AC6.2:** Documentar em `retrospectiva-epic-12.md`

---

## Análise Técnica

### Template da síntese

```markdown
# Síntese Piloto Cronos POC — YYYY-MM-DD

## Resumo Executivo

- N pilotos ativos, M entrevistados, X respostas de form
- NPS médio: Y (5 pessoas; direcional, não estatístico)
- Principal sinal positivo: [resumo 1 linha]
- Principal sinal negativo: [resumo 1 linha]
- **Próximo Epic recomendado:** Epic XX — [Nome]

## Findings categorizados

| # | Finding | Tipo | Frequência | Severidade | Decisão |
|---|---------|------|------------|------------|---------|
| 1 | "Export CSV mensal" | Missing feature | 4/5 | crítico | ✅ Próximo Epic |
| 2 | "Modal de TaskItem fecha sem salvar" | Bug | 1/5 | crítico | ✅ Hotfix imediato |
| 3 | "Não entendi botão Reabrir" | Confusion | 2/5 | moderado | ⏸️ Backlog UX polish |
| 4 | "Quero integração com clockify" | Missing feature | 1/5 | moderado | ❌ Descartado (baixa freq) |
| 5 | "Resumo diário muito útil" | Positive signal | 5/5 | — | ✅ Manter e expandir |

## Top 5 priorizados

(Findings com frequência ≥ 2 OU severidade crítica)

1. Export CSV — Missing feature, 4/5
2. Bug fechamento modal — Bug, 1/5 (crítico)
3. ...

## Justificativa do Epic

[Por que esse tema, e não outro]

## Backlog descartado

- "Integração com Clockify" — só 1 pediu, baixa prioridade
- ...

## Próximos passos

1. Hotfix do bug crítico (story 1 SP, fora do Epic novo)
2. Criar Epic 13 — [Nome]
3. Onboarding de nova rodada de pilotos em ~6 semanas
```

### Esboço do próximo Epic (template)

```markdown
# DM-012 — [Nome do domínio]

**Tipo:** [Core / Discovery / Transversal]
**Epic associado:** 13
**Stories:** [estimar 3-5]
**Status:** draft (criado a partir de validação piloto)

## Propósito

[1 parágrafo]

## Stories esboçadas

| # | Título | Notas |
|---|--------|-------|
| 13.1 | ... | ... |

## Origem do Epic

Findings dos pilotos (síntese em `_bmad-output/implementation-artifacts/DM-011-validacao-usuarios-reais/sintese-piloto.md`):
- Top finding: ...
- Frequência: N/M
```

---

## Arquivos a Criar/Modificar

| Arquivo | Ação |
|---------|------|
| `_bmad-output/implementation-artifacts/DM-011-validacao-usuarios-reais/sintese-piloto.md` | Criar |
| `_bmad-output/implementation-artifacts/DM-011-validacao-usuarios-reais/retrospectiva-epic-12.md` | Criar |
| `_bmad-output/planning-artifacts/DM-012-XXX/README.md` | Esboçar próximo domínio |
| `_bmad-output/implementation-artifacts/deferred-work.md` | Atualizar com findings descartados |

**Sem mudanças em código nesta story.**

---

## Testes

Não aplicável. AC1-AC6 substituem.

---

## Observações

- **Regra do "2+ usuários"** evita viés individual. Pessoa única reportando algo é insight; 2+ é sinal.
- **Resistir à tentação de fazer Epic gigante** — escolher 1 tema dominante, fazer pequeno, validar de novo. Mesmo princípio do projeto original.
- **Cuidado com viés de novidade:** features pedidas durante entrevista podem virar empolgação momentânea. Cruzar com analytics (uso real) ajuda a discernir.
- **Esta story fecha o ciclo BMad:** PRD → Architecture → Epics → Stories → Sprint → Retro → **Validação** → próximo PRD. O projeto está pronto pra crescer guiado por usuários.
