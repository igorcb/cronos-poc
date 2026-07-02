# Story 12.1: Recrutar 3-5 Usuários Piloto e Onboarding Pessoal

**Status:** ready-for-dev
**Domínio:** DM-011-validacao-usuarios-reais
**Epic:** Epic 12 — Validação com Usuários Reais
**Story ID:** 12.1
**Prioridade:** HIGH
**Estimativa:** 1 SP

---

## Contexto

O sistema está pronto, em produção, multi-tenant, com onboarding self-service. Mas **sem usuários reais o feedback é nulo** — toda priorização de roadmap vira palpite do Igor.

Esta story formaliza o processo de **recrutar 3-5 pessoas piloto** que tenham o problema real (controle de horas para múltiplas empresas) e fazer um onboarding **pessoal** com cada uma — não confiar 100% no fluxo automatizado já que ele nunca foi usado por estranho.

---

## História do Usuário

**Como** Igor,
**Quero** ter 3-5 pessoas reais usando o Cronos POC pela primeira semana,
**Para** validar se o sistema resolve um problema real e descobrir o que falta.

---

## Critérios de Aceite

### AC1 — Perfil dos usuários
- [ ] **AC1.1:** Lista de 8-12 candidatos identificados (espera-se 50% de aceitação → 3-5 finais)
- [ ] **AC1.2:** Critérios: freela/PJ, atende 2+ empresas, hoje usa planilha/caderno, frustração com controle atual
- [ ] **AC1.3:** Mix de origens: 1-2 conhecidos próximos (feedback honesto), 2-3 de comunidades externas (Discord/Telegram dev/PJ)

### AC2 — Convite
- [ ] **AC2.1:** Mensagem padrão do convite (template) explicando:
  - O que é o Cronos POC (timesheet multi-empresa)
  - Que é fase de validação (sem cobrança)
  - O que pedirá em troca (uso real + entrevista de 30min na semana 2)
  - Como acessar
- [ ] **AC2.2:** Enviar convite individual (não broadcast)
- [ ] **AC2.3:** Esperar resposta 48-72h antes de seguir para próximo candidato

### AC3 — Onboarding pessoal
- [ ] **AC3.1:** Para cada usuário que aceita: chamada de 15min (Meet/Zoom) explicando o sistema
- [ ] **AC3.2:** Acompanhar primeiro login pelo Google OAuth em tela compartilhada
- [ ] **AC3.3:** Acompanhar criação da primeira Empresa → Projeto → Tarefa
- [ ] **AC3.4:** Anotar fricções, dúvidas, expressões faciais ("aqui ele hesitou", "achou que ia abrir modal")

### AC4 — Suporte na primeira semana
- [ ] **AC4.1:** Canal de comunicação direto (WhatsApp/Telegram individual)
- [ ] **AC4.2:** Check-in proativo no dia 3 ("tudo certo? alguma dúvida?")
- [ ] **AC4.3:** Resolver bugs reportados em < 24h (não esperar sprint)

### AC5 — Diário de bordo
- [ ] **AC5.1:** Documento `_bmad-output/implementation-artifacts/DM-011-validacao-usuarios-reais/diario-piloto.md` com:
  - Lista de usuários (pseudônimos)
  - Data de onboarding de cada um
  - Observações por dia (fricções, perguntas, feedback espontâneo)
- [ ] **AC5.2:** Atualizar diariamente nos primeiros 7 dias

### AC6 — Métricas de sucesso
- [ ] **AC6.1:** 3+ usuários completam o onboarding (criam ao menos 1 Task)
- [ ] **AC6.2:** 2+ usuários retornam no dia 3 (analytics: pageview de usuário ≠ Igor)
- [ ] **AC6.3:** Zero bugs CRITICAL reportados que travam o uso

---

## Análise Técnica

### Template de convite (sugestão)

> Oi [nome], tudo certo?
>
> Tô finalizando um projeto pessoal: o **Cronos POC**, um timesheet multi-empresa pra freelas/PJs que prestam serviço pra 2+ clientes ao mesmo tempo (igual nós).
>
> Funciona assim: você cadastra suas empresas + projetos + tarefas e lança horas no dia a dia. Calcula automático: horas, valor, entrega. Tem dashboard, resumo diário, snapshot imutável da hourly_rate por tarefa entregue (pra auditoria).
>
> Não vou vender — tô em fase de validação, é gratuito. O que peço:
> 1. Você usa por 1-2 semanas
> 2. A gente faz uma call de 30min depois pra você criticar
>
> Topa? Se sim, te mando o link + faço um onboarding rápido contigo de 15min pra você não tropeçar.

### Diário de bordo template

```markdown
# Diário Piloto — Validação Cronos POC

## Usuários

| Pseudônimo | Origem | Onboarding | Status |
|------------|--------|------------|--------|
| Piloto A | conhecido | 2026-05-30 | ativo |
| Piloto B | discord pj | 2026-06-01 | ativo |
| Piloto C | indicação | 2026-06-02 | abandonou D3 |

## Logs por dia

### 2026-05-30
- Piloto A: onboarding em 12min. Travou no passo "criar Projeto" — não entendeu que tinha que escolher empresa primeiro. Sugestão: adicionar texto auxiliar.
- ...

### 2026-05-31
- ...
```

---

## Arquivos a Criar

| Arquivo | Ação |
|---------|------|
| `_bmad-output/implementation-artifacts/DM-011-validacao-usuarios-reais/diario-piloto.md` | Criar diário |
| `_bmad-output/implementation-artifacts/DM-011-validacao-usuarios-reais/convite-template.md` | Template do convite |

**Sem mudanças em código nesta story** — é discovery/relacionamento.

---

## Testes

Não aplicável. Métricas de AC6 substituem.

---

## Observações

- **Tempo investido por usuário:** 15min onboarding + check-in dia 3 (10min) + entrevista 30min (story 12.2) = ~1h por usuário em 2 semanas.
- **Total esperado:** ~5h investidas em 5 pessoas. Retorno: priorização real do roadmap futuro.
- **Tentação a evitar:** começar a "vender" para conhecidos sem critério. Foco em perfil que tem o problema.
