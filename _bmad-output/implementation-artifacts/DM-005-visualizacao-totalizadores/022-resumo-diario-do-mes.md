# Story 5.22: Tela de Resumo Diário do Mês (Cards / Horas / Valor por Dia)

**Status:** ready-for-dev
**Domínio:** DM-005-visualizacao-totalizadores
**Data:** 2026-05-16
**Epic:** Epic 5 — Visualização & Dashboard
**Story ID:** 5.22
**Story Key:** 5-22-resumo-diario-do-mes
**Prioridade:** high

---

## Contexto

Hoje o dashboard mostra KPIs do mês (totalizados) e a lista de tarefas individuais, mas Igor não tem uma visão **diária consolidada** — quantos cards trabalhou em cada dia, quantas horas e quanto faturou por dia.

Essa visão é fundamental para:
- Identificar dias pouco produtivos
- Comparar dias da semana (segunda vs sexta, etc.)
- Conferir lançamentos ao final do mês contra a planilha de controle

---

## História do Usuário

**Como** Igor,
**Quero** uma tela com tabela diária consolidada do mês mostrando qtde de cards, horas trabalhadas e valor por dia,
**Para** acompanhar produtividade dia a dia sem precisar somar manualmente nos cards do dashboard.

---

## Layout Proposto

```
┌───────────────────────────────────────────────────────────────┐
│ Resumo Diário                                                  │
│                                                                │
│ Mês: [Maio ▾]    (default: mês corrente)                       │
│                                                                │
│ ┌──────────────┐  ┌──────────────┐  ┌──────────────┐           │
│ │ Cards no mês │  │ Horas no mês │  │ Valor no mês │           │
│ │      71      │  │   156:15     │  │ R$ 7.031,25  │           │
│ └──────────────┘  └──────────────┘  └──────────────┘           │
│                                                                │
│ ┌──────────────────────────────────────────────────────────┐   │
│ │ Data        │ Qtde │  Horas  │   Valor                   │   │
│ ├──────────────────────────────────────────────────────────┤   │
│ │ 16/05/2026  │  5   │ 10:00   │ R$ 450,00                 │   │
│ │ 15/05/2026  │  5   │ 10:00   │ R$ 450,00                 │   │
│ │ 14/05/2026  │  5   │ 10:00   │ R$ 450,00                 │   │
│ │ 13/05/2026  │  5   │ 10:00   │ R$ 450,00                 │   │
│ │ ...                                                       │   │
│ └──────────────────────────────────────────────────────────┘   │
└───────────────────────────────────────────────────────────────┘
```

---

## Critérios de Aceite

### AC1 — Rota e navegação
- [ ] **AC1.1:** Nova rota `GET /resumo-diario` (ou `/daily-summary`) com controller dedicado (`DailySummaryController#index`)
- [ ] **AC1.2:** Link "Resumo Diário" adicionado à navbar principal (entre "Tarefas" e "Minha Conta")
- [ ] **AC1.3:** Spec verifica link na navbar (href + texto)

### AC2 — Filtro de mês
- [ ] **AC2.1:** Select dropdown com os 12 meses do ano corrente (Janeiro, Fevereiro, ..., Dezembro)
- [ ] **AC2.2:** Default: **mês corrente** (ex: "Maio" se hoje é maio/2026)
- [ ] **AC2.3:** Ao mudar a seleção, submete o form e re-renderiza a tabela e KPIs
- [ ] **AC2.4:** Param: `?month=5&year=2026` (ou apenas `?month=2026-05`)
- [ ] **AC2.5:** Anos exibidos: opcional select de ano também — **escopo desta story: apenas mês do ano corrente**

### AC3 — KPIs do mês (topo)
- [ ] **AC3.1:** Card "Cards no mês" — count de tasks **distintas** com lançamento no mês filtrado: `Task.joins(:task_items).where(task_items: { work_date: month_range }).distinct.count`
- [ ] **AC3.2:** Card "Horas no mês" — soma de `task_items.hours_worked` formatada em HH:MM
- [ ] **AC3.3:** Card "Valor no mês" — soma de `task_items.value` formatada em `R$ 1.234,56`
- [ ] **AC3.4:** Estilo dos KPIs consistente com dashboard atual (cards azul/cinza)

### AC4 — Tabela diária
- [ ] **AC4.1:** Colunas: **Data | Qtde | Horas | Valor**
- [ ] **AC4.2:** Linha por dia que **tem ao menos 1 lançamento** no mês (dias sem lançamento não aparecem — evita poluir)
- [ ] **AC4.3:** Ordenação: data decrescente (dia mais recente no topo)
- [ ] **AC4.4:** Data formatada DD/MM/AAAA
- [ ] **AC4.5:** Qtde = count de tasks **distintas** com lançamento no dia (mesma tarefa lançada 2x no mesmo dia conta 1)
- [ ] **AC4.6:** Horas em HH:MM
- [ ] **AC4.7:** Valor em `R$ 1.234,56`
- [ ] **AC4.8:** Linha **footer/total** com somatório das 3 colunas (= os 3 KPIs do topo, para confirmar visualmente)

### AC5 — Performance (sem N+1)
- [ ] **AC5.1:** Query única agrupada por `work_date`: `task_items.group(:work_date).select("work_date, COUNT(DISTINCT task_id) AS qtde, SUM(hours_worked) AS hours, SUM(value) AS value")`
- [ ] **AC5.2:** KPIs derivados do mesmo result-set (sum em Ruby após agrupar) ou query separada agregada — sem N+1

### AC6 — Multi-tenancy preparado
- [ ] **AC6.1:** Quando DM-008 (multi-tenancy) for implementado, queries escopadas a `current_user.task_items` — **não bloqueia esta story**, mas estrutura permite escope simples no controller

### AC7 — Cobertura
- [ ] **AC7.1:** Request spec GET `/resumo-diario` — default = mês corrente
- [ ] **AC7.2:** Request spec GET `/resumo-diario?month=2026-04` — filtra mês selecionado
- [ ] **AC7.3:** Request spec — KPIs corretos (1 cenário com 3 dias, 3 tasks, valores conhecidos)
- [ ] **AC7.4:** Request spec — tabela mostra apenas dias com lançamentos
- [ ] **AC7.5:** Request spec — link na navbar

---

## Análise Técnica

### Rota

```ruby
# config/routes.rb
get "resumo-diario", to: "daily_summary#index", as: :daily_summary
```

### Controller

```ruby
class DailySummaryController < ApplicationController
  def index
    @selected_month = (params[:month].presence || Date.current.strftime("%Y-%m"))
    year, month = @selected_month.split("-").map(&:to_i)
    @month_range = Date.new(year, month, 1).all_month

    @daily_rows = TaskItem
      .where(work_date: @month_range)
      .group(:work_date)
      .order(work_date: :desc)
      .pluck(
        :work_date,
        Arel.sql("COUNT(DISTINCT task_id)"),
        Arel.sql("SUM(hours_worked)"),
        Arel.sql("SUM(value)")
      )

    @kpi_cards  = @daily_rows.sum { |_, qtde, _, _| qtde }
    @kpi_hours  = @daily_rows.sum { |_, _, hours, _| hours.to_f }
    @kpi_value  = @daily_rows.sum { |_, _, _, value| value.to_f }

    @month_options = (1..12).map { |m| [I18n.t("date.month_names")[m], "#{Date.current.year}-#{m.to_s.rjust(2, '0')}"] }
  end
end
```

> **Atenção:** `@kpi_cards` calcula sum dos counts distintos por dia — não é o mesmo que count distinto no mês inteiro. Se a mesma task tiver lançamentos em 2 dias, ela conta 2x no KPI. **Decisão de design:** essa é a definição correta para "cards trabalhados por dia somados" (visão operacional). Se Igor quiser "tasks únicas no mês", precisa de query adicional `Task.joins(:task_items).where(...).distinct.count`. Confirmar antes da implementação.

### View — fragmento de filtro

```erb
<%= form_with url: daily_summary_path, method: :get, local: true do |f| %>
  <%= f.label :month, "Mês:" %>
  <%= f.select :month, @month_options, { selected: @selected_month }, onchange: "this.form.requestSubmit()" %>
<% end %>
```

### View — KPIs e tabela

KPIs reutilizam o componente atual de `TotalizerComponent` (ou cria novo `DailySummaryKpiComponent` se mais simples).

Tabela:

```erb
<table>
  <thead>
    <tr><th>Data</th><th>Qtde</th><th>Horas</th><th>Valor</th></tr>
  </thead>
  <tbody>
    <% @daily_rows.each do |date, qtde, hours, value| %>
      <tr>
        <td><%= l(date, format: :default) %></td>
        <td><%= qtde %></td>
        <td><%= hours_hm(hours) %></td>
        <td><%= number_to_currency(value, unit: "R$", separator: ",", delimiter: ".") %></td>
      </tr>
    <% end %>
  </tbody>
  <tfoot>
    <tr>
      <td><strong>Total</strong></td>
      <td><strong><%= @kpi_cards %></strong></td>
      <td><strong><%= hours_hm(@kpi_hours) %></strong></td>
      <td><strong><%= number_to_currency(@kpi_value, ...) %></strong></td>
    </tr>
  </tfoot>
</table>
```

`hours_hm(decimal)` é helper que converte `10.5` em `"10:30"` — verificar se já existe em `app/helpers/` ou criar.

---

## Arquivos a Criar/Modificar

| Arquivo | Ação |
|---------|------|
| `config/routes.rb` | Nova rota `get "resumo-diario"` |
| `app/controllers/daily_summary_controller.rb` | Criar — action `index` |
| `app/views/daily_summary/index.html.erb` | Criar — filtro + KPIs + tabela |
| `app/views/layouts/application.html.erb` | Adicionar link "Resumo Diário" na navbar (desktop + mobile menu) |
| `app/helpers/application_helper.rb` ou novo | Helper `hours_hm(decimal)` se não existir |
| `spec/requests/daily_summary_spec.rb` | Criar — specs de filtro, KPIs, tabela, link navbar |

---

## Testes

- [ ] GET `/resumo-diario` sem param → usa mês corrente
- [ ] GET `/resumo-diario?month=2026-04` → filtra abril
- [ ] Com 3 task_items em 3 dias distintos → tabela tem 3 linhas, ordenadas desc
- [ ] Com 2 task_items na mesma task no mesmo dia → linha mostra Qtde=1
- [ ] KPIs somam corretamente as 3 colunas
- [ ] Link "Resumo Diário" presente na navbar (desktop + mobile)
- [ ] Mês sem lançamentos → tabela vazia + KPIs zerados (R$ 0,00, 00:00, 0 cards)

---

## Dependências

- `task_items.work_date` — **já existe**
- `task_items.hours_worked` e `task_items.value` — **já existem** (story 4.15)
- Padrão de helpers de formatação HH:MM e R$ — **já estabelecido**

---

## Observações

- **Por que não exibir dias sem lançamento (AC4.2)?** Manter foco — uma linha vazia "16/05/2026 | 0 | 00:00 | R$ 0,00" polui. Igor sabe que dia não trabalhou.
- **Por que não permitir escolher ano (AC2.5)?** Escopo mínimo. Igor pediu meses do ano corrente. Se precisar histórico, criar story separada com select de ano + mês.
- **Sobre o KPI "Cards no mês":** ver nota na Análise Técnica — confirmar definição com Igor antes da implementação (sum de counts distintos por dia vs count distinto no mês inteiro).

---

## Estimativa

**2 story points** (~3h) — controller + view + helper + 6 specs + ajuste navbar.
