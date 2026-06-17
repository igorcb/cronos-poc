# DM-010 — Consistência de Métricas e Nomenclatura

## Contexto

Durante inspeção da aplicação em produção (17/06/2026), foi identificada uma divergência
de valores e nomenclatura entre o Dashboard e a página Resumo Diário.

---

## Bug #1 — Divergência entre "Tasks Mês" e "Cards no mês"

### Evidência observada

| Tela | KPI | Valor |
|------|-----|-------|
| Dashboard | Tasks Mês | **61** |
| Resumo Diário | Cards no mês | **81** |

Diferença: **20 unidades** para o mesmo período (Junho/2026).

### Causa raiz provável

Os dois KPIs contam entidades diferentes:

- **Tasks Mês (Dashboard):** conta `tasks` distintas criadas/registradas no mês.
- **Cards no mês (Resumo Diário):** conta `task_items` (apontamentos de tempo) — uma task pode gerar múltiplos task_items em dias distintos, inflando o número.

**Exemplo:** uma task com apontamentos em 3 dias diferentes conta como 1 no Dashboard e 3 no Resumo Diário.

### Impacto

- **Alto:** usuário não consegue reconciliar os números entre as duas telas.
- Gera desconfiança na integridade dos dados.
- Impossibilita uso do Resumo Diário como fonte de verdade para quantidade de tarefas.

### Correção esperada

O KPI "Cards no mês" do Resumo Diário deve contar **tasks distintas** com apontamento no mês,
igual ao critério do Dashboard — ou deixar explícito que conta apontamentos (task_items).

---

## Melhoria #1 — Padronização da nomenclatura "Tarefas do mês"

### Problema atual

Existem dois rótulos diferentes para o mesmo conceito em telas distintas:

| Tela | Rótulo atual |
|------|-------------|
| Dashboard | **Tasks Mês** |
| Resumo Diário | **Cards no mês** |

O rótulo em inglês ("Tasks") misturado com português é inconsistente.
"Cards" não é um termo do domínio e causa confusão.

### Solução

Padronizar ambos os rótulos para **"Tarefas do mês"** em todo o sistema:

| Tela | Rótulo atual | Rótulo proposto |
|------|-------------|-----------------|
| Dashboard | Tasks Mês | **Tarefas do mês** |
| Resumo Diário | Cards no mês | **Tarefas do mês** |

---

## Histórias de usuário

### HU1: Corrigir contagem divergente de tarefas entre Dashboard e Resumo Diário

**Como** usuário do Cronos POC  
**Quero** que o número de tarefas do mês seja o mesmo no Dashboard e no Resumo Diário  
**Para** poder confiar nos dados e reconciliar as duas telas sem ambiguidade

**Critérios de Aceite:**
- [ ] AC1: Dashboard "Tarefas do mês" e Resumo Diário "Tarefas do mês" exibem o mesmo valor para o mesmo mês
- [ ] AC2: O valor representa tasks distintas (não task_items duplicados por dia)
- [ ] AC3: Ao trocar o mês no Resumo Diário, o KPI atualiza corretamente mantendo a mesma lógica de contagem

**Estimativa:** 3 story points (~4 horas)

---

### HU2: Padronizar nomenclatura dos KPIs para português

**Como** usuário do Cronos POC  
**Quero** ver todos os rótulos de KPI em português e com nomenclatura consistente  
**Para** entender imediatamente o que cada métrica representa, sem confusão

**Critérios de Aceite:**
- [ ] AC1: Dashboard: "Tasks Mês" renomeado para "Tarefas do mês"
- [ ] AC2: Resumo Diário: "Cards no mês" renomeado para "Tarefas do mês"
- [ ] AC3: Nenhum outro rótulo de KPI usa termos em inglês ou jargão técnico ("cards", "tasks")
- [ ] AC4: Alteração cobre versão desktop e mobile

**Estimativa:** 1 story point (~1 hora)

---

## Considerações Técnicas

- Verificar query do `DashboardController` (Tasks Mês) vs query do `ResumoDiarioController` (Cards no mês)
- Confirmar se Dashboard usa `Task.where(month)` e Resumo Diário usa `TaskItem.where(month)` — se sim, alinhar critério
- Rótulos estão provavelmente em: `app/views/dashboard/index.html.erb` e `app/views/resumo_diario/index.html.erb`
- Garantir cobertura de specs para a correção da query

## Checklist de Implementação

- [ ] Identificar e corrigir query divergente no controller do Resumo Diário
- [ ] Renomear rótulo "Tasks Mês" → "Tarefas do mês" no Dashboard
- [ ] Renomear rótulo "Cards no mês" → "Tarefas do mês" no Resumo Diário
- [ ] Adicionar/atualizar specs para validar contagem consistente
- [ ] Validar em produção que ambos os valores batem
