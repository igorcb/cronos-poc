# Story 5.23: Padronizar Ícones dos KPIs do Mês em Verde

**Status:** done
**Domínio:** DM-005-visualizacao-totalizadores
**Data:** 2026-05-20
**Epic:** Epic 5 — Visualização & Dashboard
**Story ID:** 5.23
**Story Key:** 5-23-icones-kpis-mes-verdes
**Prioridade:** low
**Tipo:** Ajuste visual

---

## Contexto

Hoje o dashboard tem 9 KPIs cada um com cor de ícone diferente:

| KPI | Cor atual |
|-----|-----------|
| Tasks Hoje (`_daily_task_count`) | `text-blue-400` |
| Horas Hoje (`_daily_hours`) | `text-blue-400` |
| Valor Hoje (`_daily_value`) | `text-yellow-400` |
| **Tasks Mês** (`_monthly_task_count`) | `text-green-400` ✅ |
| **Horas Mês** (`_monthly_hours`) | `text-green-400` ✅ |
| **Valor Mês** (`_monthly_value`) | `text-yellow-400` ❌ |
| Entregas do Mês (`_delivered_count`) | `text-blue-400` |
| Horas Entregues (`_delivered_hours`) | `text-blue-400` |
| Valor Entregue (`_delivered_value`) | `text-blue-400` |
| Média por Entrega (`_avg_per_delivery`) | `text-blue-400` |

O trio **Tasks Mês / Horas Mês / Valor Mês** tem 2 verdes mas 1 amarelo — quebra a consistência visual.

---

## História do Usuário

**Como** Igor,
**Quero** os 3 KPIs do trio "Mês" (Tasks/Horas/Valor) com ícones na mesma cor verde,
**Para** que o dashboard tenha consistência visual e o agrupamento dos KPIs mensais seja imediatamente reconhecível.

---

## Critérios de Aceite

- [x] **AC1:** `app/views/dashboard/_monthly_value.html.erb` — alterar `text-yellow-400` → `text-green-400` no SVG
- [x] **AC2:** `_monthly_task_count` e `_monthly_hours` — permanecem `text-green-400` (já estão corretos)
- [x] **AC3:** Demais KPIs (`_daily_*`, `_delivered_*`, `_avg_per_delivery`) — **não alterar**
- [x] **AC4:** Validação via Playwright MCP: screenshot do dashboard mostra os 3 ícones do trio "Mês" todos em verde

---

## Análise Técnica

Mudança cirúrgica de 1 caractere — substituir `yellow` por `green` na classe Tailwind do SVG em `_monthly_value.html.erb` linha 4.

```diff
- <svg class="h-6 w-6 text-yellow-400" ...>
+ <svg class="h-6 w-6 text-green-400" ...>
```

Sem impacto em controllers, models, JS, Turbo Streams ou specs (a cor não é assertion em nenhum spec — verificado).

---

## Arquivos a Modificar

| Arquivo | Ação |
|---------|------|
| `app/views/dashboard/_monthly_value.html.erb` | `text-yellow-400` → `text-green-400` (1 ocorrência, linha 4) |

---

## Testes

- [ ] Suite RSpec continua passando 880/880 com 100% cobertura (sem impacto)
- [ ] Validação visual via Playwright MCP — screenshot do dashboard

---

## Estimativa

**0.5 story point** (~15min) — alteração de 1 caractere + validação Playwright + commit/PR.

---

## Observações

- Não inclui padronização dos outros 6 KPIs (daily/delivered/avg) — escopo decidido com PM
- Se no futuro quiser padronizar tudo, criar story separada
