# Epic DM-010: Consistência de Métricas e Nomenclatura

**Domínio:** DM-010-consistencia-metricas
**Tipo:** Correção / Qualidade de Dados
**Status:** Planejado (criado 2026-06-17)
**Prioridade:** Alta (divergência de dados gera desconfiança no sistema)

## Objetivo

Corrigir a divergência de contagem entre o KPI "Tasks Mês" (Dashboard) e o KPI "Cards no mês" (Resumo Diário), e padronizar a nomenclatura de todos os KPIs de quantidade de tarefas para "Tarefas do mês" em português consistente.

## Valor de Negócio

A confiança nos dados é fundamental para um sistema de time tracking. Quando duas telas do mesmo sistema exibem números diferentes para o mesmo conceito — quantidade de tarefas no mês — o usuário não sabe qual acreditar e perde a confiança no produto.

- Eliminar a confusão causada pela divergência de 61 vs 81 para junho/2026
- Permitir que o usuário reconcilie Dashboard e Resumo Diário sem ambiguidade
- Padronizar terminologia em português eliminando termos em inglês ("Tasks") e jargão técnico ("Cards")

**Momento de valor:** Igor abre o Dashboard, vê "Tarefas do mês: 61", vai ao Resumo Diário e confirma "Tarefas do mês: 61" — os números batem, o sistema é confiável.

## Dependências

- **Predecessores:** DM-005 (Visualização & Totalizadores — onde os KPIs foram criados)
- **Sucessores:** nenhum

## Decisões Arquiteturais

| Decisão | Escolha | Justificativa |
|---------|---------|---------------|
| Critério de contagem | Tasks distintas por mês | Alinha com o conceito de "tarefa" do domínio |
| Nomenclatura | "Tarefas do mês" | Português, sem jargão, consistente entre telas |
| Escopo da correção | Dashboard + Resumo Diário | Ambas as telas têm o mesmo KPI com valores divergentes |

## Critérios de Aceite do Épico

- [ ] Dashboard "Tarefas do mês" e Resumo Diário "Tarefas do mês" exibem o mesmo valor para o mesmo período
- [ ] O valor representa tasks distintas (não task_items duplicados por dia)
- [ ] Nenhum KPI de quantidade usa termos em inglês ("Tasks") ou jargão ("Cards")
- [ ] Alteração cobre versão desktop e mobile
- [ ] Specs cobrem a consistência da contagem

## Stories

| # | Arquivo | Nome |
|---|---------|------|
| 001 | `001-corrigir-contagem-divergente-tarefas-mes.md` | Corrigir contagem divergente de tarefas entre Dashboard e Resumo Diário |
| 002 | `002-padronizar-nomenclatura-kpis-portugues.md` | Padronizar nomenclatura dos KPIs para "Tarefas do mês" |

## Requisitos Rastreados

- BUG-010-01: Divergência de contagem Tasks Mês vs Cards no mês
- UX-010-01: Padronização de nomenclatura em português
