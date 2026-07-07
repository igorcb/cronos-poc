# Story 12.2: Coletar Feedback Estruturado (Entrevistas + Form)

**Status:** ready-for-dev
**Domínio:** DM-011-validacao-usuarios-reais
**Epic:** Epic 12 — Validação com Usuários Reais
**Story ID:** 12.2
**Prioridade:** HIGH
**Estimativa:** 1 SP

---

## Contexto

Com 3-5 piloto usando o sistema por 2 semanas (Story 12.1), é hora de **extrair feedback de forma sistemática**. Sem método, virá ruído de "tá bom" e "gostei". Com método (entrevista guiada + form curto), vem material para decidir o próximo Epic.

Esta story formaliza dois mecanismos complementares:
- **Entrevista qualitativa** (30min, por pessoa) — capta nuances, surpresas, frustrações
- **Form quantitativo** (5min, anônimo) — captura NPS, prioridades, métricas comparáveis

---

## História do Usuário

**Como** Igor,
**Quero** ter dados estruturados de feedback dos 3-5 usuários piloto,
**Para** decidir o próximo Epic com base em sinal real, não palpite.

---

## Critérios de Aceite

### AC1 — Entrevista guiada
- [ ] **AC1.1:** Roteiro semi-estruturado em `_bmad-output/implementation-artifacts/DM-011-validacao-usuarios-reais/roteiro-entrevista.md`
- [ ] **AC1.2:** Entrevistas agendadas com cada piloto após 7-14 dias de uso
- [ ] **AC1.3:** Duração: 30min, gravada (com consentimento) para revisitar depois
- [ ] **AC1.4:** Notas transcritas em `entrevista-PILOTO_X.md` (um arquivo por usuário, pseudonimizado)

### AC2 — Roteiro da entrevista (10 perguntas)
- [ ] **AC2.1:** Aquecimento: "Conta um dia típico seu antes do Cronos POC"
- [ ] **AC2.2:** Uso: "Quando foi a última vez que abriu? O que fez?"
- [ ] **AC2.3:** Frustração: "Qual foi o momento que mais te frustrou?"
- [ ] **AC2.4:** Surpresa: "Algo te surpreendeu (positivamente ou negativamente)?"
- [ ] **AC2.5:** Comparação: "Se voltasse pra planilha amanhã, sentiria falta de quê?"
- [ ] **AC2.6:** Faltante: "Tem algo que esperava ter e não tem?"
- [ ] **AC2.7:** Confusão: "Em algum momento ficou perdido? Onde?"
- [ ] **AC2.8:** Pagamento: "Você pagaria por isso? Quanto?"
- [ ] **AC2.9:** Indicação: "Indicaria pra alguém? Quem?"
- [ ] **AC2.10:** Wishlist: "Se eu fosse o gênio da lâmpada, qual sua primeira melhoria?"

### AC3 — Form quantitativo
- [ ] **AC3.1:** Form criado (Tally.so / Google Forms — ferramenta gratuita)
- [ ] **AC3.2:** Perguntas (todas escala 1-5 ou múltipla escolha curta):
  - "De 1-5, quão útil foi o Cronos POC?"
  - "De 1-10, quão provável é você indicar (NPS)?"
  - "Use cada feature: (lista de 9 KPIs + telas) — múltipla escolha 'uso sempre / uso às vezes / nunca usei'"
  - "Qual a feature mais importante pra você?"
  - "Qual a feature menos importante / nunca usou?"
  - "O que está faltando? (texto livre, curto)"
- [ ] **AC3.3:** Enviar link após entrevista (não antes — entrevista ancora qualitativo)

### AC4 — Documentação
- [ ] **AC4.1:** Transcrições/notas de entrevistas salvas (anonimizadas) em `entrevista-PILOTO_X.md`
- [ ] **AC4.2:** Resultados do form exportados (CSV) e salvos em `form-resultados.csv`
- [ ] **AC4.3:** Dados de analytics (do Story 11.3) cruzados com feedback (ex: usuário disse que usa resumo diário, mas analytics mostra 0 visitas)

### AC5 — Métricas de cobertura
- [ ] **AC5.1:** 100% dos pilotos ativos entrevistados (esperado: 3-5)
- [ ] **AC5.2:** 100% dos pilotos respondem o form
- [ ] **AC5.3:** Notas/transcrições de entrevista em pelo menos 2 páginas por usuário

---

## Análise Técnica

### Roteiro detalhado (template)

```markdown
# Roteiro de Entrevista — Piloto X

**Duração esperada:** 30min
**Gravação:** sim (consentimento verbal no início)
**Pseudônimo:** Piloto X
**Data:** YYYY-MM-DD

## Abertura (2min)
- Agradecer + recapitular: "Você usou o Cronos POC por ~10 dias. Vou te fazer algumas perguntas. Honestidade brutal é o que ajuda, ok?"
- Pedir consentimento para gravar

## Aquecimento (5min)
**P1:** Antes de usar o Cronos, como você controlava horas?
**P2:** Que problema isso te causava no dia a dia?

## Uso real (10min)
**P3:** Quando foi a última vez que abriu o Cronos? O que fez?
**P4:** Frequência típica: quantas vezes por semana?
**P5:** Em quais momentos do dia você abre?

## Crítica direta (10min)
**P6:** Qual foi o momento mais frustrante usando?
**P7:** Você ficou perdido em alguma tela? Quando?
**P8:** Tem algo que esperava ter e não tem?
**P9:** Se voltasse pra planilha amanhã, sentiria falta de quê?

## Direcional (3min)
**P10:** Pagaria por isso? Quanto?
**P11:** Indicaria pra quem?
**P12:** Wishlist mágica: 1 melhoria.

## Fechamento
- Agradecer
- Avisar que vai enviar form curto
- Perguntar se pode voltar a contatá-lo em 1 mês
```

### Form (sugestão Tally/Google Forms)

```
1. De 1-5, quão útil foi o Cronos POC pra você?
   [ 1 ] [ 2 ] [ 3 ] [ 4 ] [ 5 ]

2. De 0-10, qual a chance de você recomendar pra outro freela/PJ?
   [ 0 ] ... [ 10 ]

3. Marque as features que VOCÊ USOU pelo menos 1 vez:
   ☐ Dashboard (visão geral)
   ☐ Criar tarefa
   ☐ Lançar horas (modal)
   ☐ Editar tarefa
   ☐ Entregar tarefa
   ☐ Reabrir tarefa
   ☐ Resumo diário
   ☐ Filtros
   ☐ Alterar senha
   ☐ Login com Google

4. Qual feature foi a MAIS IMPORTANTE pra você?
   (texto livre, 1 linha)

5. Qual feature você NUNCA USOU ou achou inútil?
   (texto livre, 1 linha)

6. O que mais está faltando?
   (texto livre, 3 linhas)
```

---

## Arquivos a Criar

| Arquivo | Ação |
|---------|------|
| `roteiro-entrevista.md` | Template do roteiro |
| `entrevista-PILOTO_A.md` (etc.) | Notas/transcrição por usuário |
| `form-resultados.csv` | Export do form |
| `LINK_FORM.md` | URL do form ativo + responses count |

**Sem mudanças em código.** Só documentação.

---

## Testes

Não aplicável. AC5 substitui.

---

## Observações

- **Gravar entrevistas** ajuda a revisitar nuances depois. Limita-se à transcrição se incomodar (próprio ou usuário).
- **Não defender o produto** durante a entrevista. Cada vez que sentir vontade de dizer "ah, isso já tá nos planos", **morder a língua e anotar**.
- **NPS com 5 pessoas não é estatístico** — é direcional. Útil para tendência (todos 8+ → algo certo; todos 5- → produto não resolve).
- **Cruzar com analytics da 11.3** é o que dá robustez: "ele disse que usa resumo diário, mas visitou só 1x" é insight precioso.
