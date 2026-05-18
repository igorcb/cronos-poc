# Story 5.22: Tela de Resumo Diário do Mês (Cards / Horas / Valor por Dia)

**Status:** done
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
- [x] **AC1.1:** Nova rota `GET /resumo-diario` (ou `/daily-summary`) com controller dedicado (`DailySummaryController#index`)
- [x] **AC1.2:** Link "Resumo Diário" adicionado à navbar principal (entre "Tarefas" e "Minha Conta")
- [x] **AC1.3:** Spec verifica link na navbar (href + texto)

### AC2 — Filtro de mês
- [x] **AC2.1:** Select dropdown com os 12 meses do ano corrente (Janeiro, Fevereiro, ..., Dezembro)
- [x] **AC2.2:** Default: **mês corrente** (ex: "Maio" se hoje é maio/2026)
- [x] **AC2.3:** Ao mudar a seleção, submete o form e re-renderiza a tabela e KPIs
- [x] **AC2.4:** Param: `?month=5&year=2026` (ou apenas `?month=2026-05`)
- [x] **AC2.5:** Anos exibidos: opcional select de ano também — **escopo desta story: apenas mês do ano corrente**

### AC3 — KPIs do mês (topo)
- [x] **AC3.1:** Card "Cards no mês" — count de tasks **distintas** com lançamento no mês filtrado: `Task.joins(:task_items).where(task_items: { work_date: month_range }).distinct.count`
- [x] **AC3.2:** Card "Horas no mês" — soma de `task_items.hours_worked` formatada em HH:MM
- [x] **AC3.3:** Card "Valor no mês" — soma de `task_items.value` formatada em `R$ 1.234,56`
- [x] **AC3.4:** Estilo dos KPIs consistente com dashboard atual (cards azul/cinza)

### AC4 — Tabela diária
- [x] **AC4.1:** Colunas: **Data | Qtde | Horas | Valor**
- [x] **AC4.2:** Linha por dia que **tem ao menos 1 lançamento** no mês (dias sem lançamento não aparecem — evita poluir)
- [x] **AC4.3:** Ordenação: data decrescente (dia mais recente no topo)
- [x] **AC4.4:** Data formatada DD/MM/AAAA
- [x] **AC4.5:** Qtde = count de tasks **distintas** com lançamento no dia (mesma tarefa lançada 2x no mesmo dia conta 1)
- [x] **AC4.6:** Horas em HH:MM
- [x] **AC4.7:** Valor em `R$ 1.234,56`
- [x] **AC4.8:** Linha **footer/total** com somatório das 3 colunas (= os 3 KPIs do topo, para confirmar visualmente)

### AC5 — Performance (sem N+1)
- [x] **AC5.1:** Query única agrupada por `work_date`: `task_items.group(:work_date).select("work_date, COUNT(DISTINCT task_id) AS qtde, SUM(hours_worked) AS hours, SUM(value) AS value")`
- [x] **AC5.2:** KPIs derivados do mesmo result-set (sum em Ruby após agrupar) ou query separada agregada — sem N+1

### AC6 — Multi-tenancy preparado
- [x] **AC6.1:** Quando DM-008 (multi-tenancy) for implementado, queries escopadas a `current_user.task_items` — **não bloqueia esta story**, mas estrutura permite escope simples no controller

### AC7 — Cobertura
- [x] **AC7.1:** Request spec GET `/resumo-diario` — default = mês corrente
- [x] **AC7.2:** Request spec GET `/resumo-diario?month=2026-04` — filtra mês selecionado
- [x] **AC7.3:** Request spec — KPIs corretos (1 cenário com 3 dias, 3 tasks, valores conhecidos)
- [x] **AC7.4:** Request spec — tabela mostra apenas dias com lançamentos
- [x] **AC7.5:** Request spec — link na navbar

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

---

## Dev Agent Record

### Implementation Plan

- **Decisão de design AC3.1 (confirmada com Igor):** KPI "Cards no mês" = **soma dos counts distintos por dia** (opção 2). Exemplo: 4 dias × 5 cards/dia → KPI Cards = 20. Bate exatamente com o footer da tabela.
- **Helper reaproveitado:** `ApplicationHelper#hours_to_hm(decimal)` já existia — não criei novo helper.
- **Query única (AC5.1):** `TaskItem.where(work_date: month_range).group(:work_date).order(work_date: :desc).pluck(:work_date, COUNT(DISTINCT task_id), SUM(hours_worked), SUM(value))` — sem N+1.
- **KPIs derivados do mesmo result-set (AC5.2):** `sum` em Ruby sobre as 4 colunas do pluck — sem query adicional.
- **Sanitização do param `month`:** regex `\A\d{4}-\d{2}\z` + range 1–12. Inputs malformados (string inválida, array, mês 00/13) caem no default (mês corrente). Sem rescue desnecessário.
- **Mobile-first:** select de mês `min-h-[44px]`, grid `grid-cols-1 sm:grid-cols-3` para KPIs, tabela em `overflow-x-auto`, padding `p-4 sm:p-6`.
- **Acessibilidade:** `<h1>` semântico, `<section aria-labelledby>`, `<caption class="sr-only">`, `scope="col"`, `scope="row"` no footer, labels com `for=`, `role="status"` no estado vazio.
- **Navbar:** link "Resumo Diário" adicionado entre "Tarefas" e "Minha Conta" — desktop (linha 48) e mobile menu (linha 89) — coberto por spec verificando string completa de `<a class="..." href="/resumo-diario">Resumo Diário</a>` (anti falso-positivo, conforme `feedback_navbar_link_sem_spec.md` e `feedback_specs_falso_positivo_strings_compartilhadas.md`).

### Completion Notes

- 34 specs novos em `spec/requests/daily_summary_spec.rb` cobrindo AC1–AC7 (26 da implementação + 8 do QA review: 1 row_for por linha × 3 + 2 ano-corrente + 3 boundary + 1 aria-live + 1 H1 ano futuro − 2 reescritos = 34).
- 6 specs adicionados em `spec/requests/accessibility_spec.rb` para AC1+AC4+AC6.
- 6 specs adicionados em `spec/requests/mobile_first_spec.rb` para AC2+AC3+AC4 mobile.
- Suite final pós-QA: **922 examples, 0 failures, 100.0% line coverage**.
- Sem alterações em modelos, migrations ou helpers existentes.
- QA findings aplicados: 3 HIGH (H1, H2, H3), 5 MEDIUM (M1, M2, M3, M4, M5), 1 LOW (L1). 10 memory files de feedback registrados em `~/.claude/projects/-home-igor-rails-app-cronos-poc/memory/feedback_qa_022_*.md` para evitar repetição em stories futuras.

### File List

| Arquivo | Ação |
|---------|------|
| `config/routes.rb` | Modificado — nova rota `get "resumo-diario"` |
| `app/controllers/daily_summary_controller.rb` | **Novo** — action `index` com sanitização de param e query única agrupada |
| `app/views/daily_summary/index.html.erb` | **Novo** — filtro de mês, KPIs (Cards/Horas/Valor) e tabela diária com footer total |
| `app/views/layouts/application.html.erb` | Modificado — link "Resumo Diário" nas duas versões da navbar (desktop + mobile) |
| `spec/requests/daily_summary_spec.rb` | **Novo** — 26 specs cobrindo AC1–AC7 |
| `spec/requests/accessibility_spec.rb` | Modificado — describe novo "GET /resumo-diario" (6 specs WCAG) |
| `spec/requests/mobile_first_spec.rb` | Modificado — describe novo "GET /resumo-diario" (6 specs mobile-first) |
| `config/locales/pt-BR.yml` | Modificado — declarado `date.month_names`, `date.abbr_month_names`, `date.day_names`, `date.abbr_day_names` (estavam ausentes — causavam Translation missing) |
| `_bmad-output/implementation-artifacts/DM-005-visualizacao-totalizadores/022-resumo-diario-do-mes.md` | Atualizado — Status `done`, ACs, Dev Agent Record |
| `_bmad-output/implementation-artifacts/DM-005-visualizacao-totalizadores/sprint-status.yaml` | Atualizado — story para `done`, domínio para `done` 100% |
| `.playwright-mcp/022-resumo-diario-validation-default.png` | Screenshot — validação Maio com dados |
| `.playwright-mcp/022-resumo-diario-validation-abril-empty.png` | Screenshot — validação empty state Abril |

### Change Log

- 2026-05-18 — Implementação completa da story 5.22. Rota `/resumo-diario`, controller, view, navbar (desktop + mobile) e 38 novos specs. Suite: 914/914 passando, 100% cobertura.
- 2026-05-18 — Aplicadas correções do QA review (HIGH + MEDIUM + LOW):
  - **H1:** `sanitize_month_param` valida `year == Date.current.year` (story AC2.5 enforce). Specs adicionais para `1999-04` e ano futuro.
  - **H2:** Specs de navbar trocados para regex contextual (`<nav>...href=.../resumo-diario</nav>` e `id="mobile-menu"...href=.../resumo-diario`) — menos frágil a refactors de classes Tailwind.
  - **H3:** Spec único de "renders one row per day" substituído por 3 specs (`row_for(16/04)`, `row_for(15/04)`, `row_for(14/04)`) que verificam Qtde + Horas + Valor por linha. Anti falso-positivo de troca de colunas.
  - **M1:** Estado vazio ganhou `aria-live="polite" aria-atomic="true"` (consistência com `tasks/index`). Spec novo.
  - **M2:** 3 specs novos cobrindo boundary: dia 01/04, dia 30/04 e exclusão de 31/03 ao filtrar abril.
  - **M3:** `MONTH_NAMES_PT` removido; controller usa `I18n.t("date.month_names")` (DRY com pt-BR.yml). Spec ajustado.
  - **M4:** Tipos normalizados no controller via `.map` sobre o `pluck` (`[date, qtde.to_i, hours.to_f, value.to_f]`). View limpa, sem `.to_i`/`.to_f` redundantes.
  - **M5:** Comentário/título do spec "2026-00" corrigido para refletir comportamento real (`(1..12).include? falhar`).
  - **L1:** `aria-label="..."` redundantes removidos dos 3 cards de KPI; texto visível em `<p>` é semântico.
- Suite final: **922 examples, 0 failures, 100.0% line coverage** (8 novos specs vs. 914 anteriores).
- 2026-05-18 — Validação Playwright revelou bug crítico: `I18n.t("date.month_names")` retornava `"Translation missing..."` (String) porque `config/locales/pt-BR.yml` não declarava `month_names`/`day_names`. Indexar `[m]` retornava UMA LETRA, gerando `<option>r</option><option>a</option>...` e caption "Resumo diário de l". Specs com `include(...)` passavam por coincidência. **Fix:** declarado `date.month_names`, `date.abbr_month_names`, `date.day_names`, `date.abbr_day_names` em pt-BR.yml + spec guard explícito (`expect(I18n.t(...)).to be_a(Array)`) + spec usando lista hardcoded "Janeiro..Dezembro" via regex `<option value="...">Nome</option>`. Memory `feedback_qa_022_i18n_translation_missing_falso_positivo.md` registrada como CRITICAL.
- Suite final pós-Playwright: **923 examples, 0 failures, 100.0% line coverage** (+1 spec do guard I18n).
- Screenshots: `.playwright-mcp/022-resumo-diario-validation-default.png` (Maio com dados) e `.playwright-mcp/022-resumo-diario-validation-abril-empty.png` (empty state Abril).

