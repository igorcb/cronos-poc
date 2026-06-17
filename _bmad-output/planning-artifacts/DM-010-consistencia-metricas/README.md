# DM-010: Consistência de Métricas e Nomenclatura

**Domínio:** Correção / Qualidade de Dados
**Epic Relacionado:** Epic 10
**Status:** Planejado (2026-06-17)

## Descrição

Domínio responsável por corrigir a divergência de contagem entre o KPI "Tasks Mês" do
Dashboard (61) e o KPI "Cards no mês" do Resumo Diário (81) para o mesmo período
(Junho/2026), e padronizar a nomenclatura de todos os KPIs de quantidade de tarefas
para "Tarefas do mês" em português.

## Capacidades

| Capacidade | Descrição |
|------------|-----------|
| Correção de contagem | Unificar critério de contagem para tasks distintas em ambas as telas |
| Padronização de nomenclatura | Renomear KPIs para "Tarefas do mês" em todo o sistema |

## Regras de Negócio

1. **Critério único:** Ambos os KPIs devem contar `Task.distinct` com apontamento no período — não `TaskItem.count`
2. **Nomenclatura em português:** Nenhum KPI de contagem usa termos em inglês ("Tasks") ou jargão técnico ("Cards")
3. **Consistência entre telas:** Dashboard e Resumo Diário devem exibir o mesmo valor para o mesmo mês

## Requisitos Cobertos

### Bugs
- BUG-010-01: Divergência de contagem Tasks Mês (61) vs Cards no mês (81) — Junho/2026

### Melhorias de UX
- UX-010-01: Padronização de nomenclatura KPIs em português sem jargão

## Stories

| Story | Nome | Status |
|-------|------|--------|
| 10.1 | Corrigir contagem divergente de tarefas entre Dashboard e Resumo Diário | Pendente |
| 10.2 | Padronizar nomenclatura dos KPIs para "Tarefas do mês" | Pendente |
