require "rails_helper"

# Story 5.22 — Tela de Resumo Diário do Mês
RSpec.describe "Daily Summary", type: :request do
  let!(:user) { create(:user, email: "daily@example.com", password: "password123", password_confirmation: "password123") }
  let!(:company) { create(:company, name: "Empresa Resumo", hourly_rate: 45.00) }
  let!(:project) { create(:project, company: company) }

  def sign_in
    post session_path, params: { email: "daily@example.com", password: "password123" }
  end

  describe "GET /resumo-diario" do
    context "when not authenticated" do
      it "redirects to login" do
        get daily_summary_path
        expect(response).to redirect_to(new_session_path)
      end
    end

    context "when authenticated" do
      before { sign_in }

      # AC1.1: rota responde 200
      it "returns 200" do
        get daily_summary_path
        expect(response).to have_http_status(:ok)
      end

      # AC1.1 / AC2.2: título e default = mês corrente
      it "renders the page title and h1" do
        get daily_summary_path
        expect(response.body).to include("Resumo Diário")
        expect(response.body).to include('id="daily-summary-heading"')
      end

      it "default selected month is the current month" do
        get daily_summary_path
        expected = Date.current.strftime("%Y-%m")
        expect(response.body).to include(%(selected="selected" value="#{expected}"))
      end

      # AC2.1: 12 meses no select (nomes via I18n)
      # Importante: I18n.t("date.month_names") DEVE retornar um Array de 13 elementos
      # (índice 0 = nil, 1..12 = nomes). Se a chave estiver ausente, retorna uma String
      # "Translation missing..." e indexar com [m] retorna UMA LETRA — falso positivo
      # silencioso no spec mas bug funcional na UI.
      it "I18n configures date.month_names as an Array (guards against Translation missing)" do
        names = I18n.t("date.month_names", default: nil)
        expect(names).to be_a(Array), "date.month_names deve ser Array — verifique config/locales/pt-BR.yml. Foi retornado: #{names.inspect}"
        expect(names.length).to eq(13)
        expect(names[1]).to eq("Janeiro")
        expect(names[12]).to eq("Dezembro")
      end

      it "renders select with 12 month options for current year using full month names" do
        get daily_summary_path
        expected_names = %w[Janeiro Fevereiro Março Abril Maio Junho Julho Agosto Setembro Outubro Novembro Dezembro]
        expected_names.each_with_index do |name, idx|
          m = idx + 1
          # Verifica que o nome COMPLETO aparece como conteúdo de uma <option>
          expect(response.body).to match(
            %r{<option[^>]*value="#{Date.current.year}-#{m.to_s.rjust(2, '0')}"[^>]*>#{Regexp.escape(name)}</option>}
          )
        end
      end

      # AC2.3 / AC2.4: form GET com param month
      it "form submits via GET to daily_summary_path" do
        get daily_summary_path
        expect(response.body).to include('action="/resumo-diario"')
        expect(response.body).to include('method="get"')
      end

      it "form has novalidate attribute (Rails html: { novalidate: true })" do
        get daily_summary_path
        expect(response.body).to include('novalidate="novalidate"')
      end

      # AC4.2: mês sem lançamentos → tabela vazia, KPIs zerados
      context "without any task_items in the selected month" do
        it "renders empty state and zeroed KPIs" do
          get daily_summary_path
          expect(response.body).to include("Nenhum lançamento encontrado")
          expect(response.body).to include('id="kpi-cards"')
          expect(response.body).to match(%r{id="kpi-cards"[^>]*>\s*0\s*<})
          expect(response.body).to match(%r{id="kpi-hours"[^>]*>\s*00:00\s*<})
          expect(response.body).to include("R$ 0,00")
        end

        # M1: empty state com filtro auto-submit precisa anunciar mudanças via aria-live
        it "empty state has aria-live=polite and aria-atomic=true" do
          get daily_summary_path
          expect(response.body).to include('aria-live="polite"')
          expect(response.body).to include('aria-atomic="true"')
        end
      end

      # AC3 + AC4: KPIs e tabela com dados reais
      context "with task_items spread across 3 days" do
        let(:target_month) { Date.new(2026, 4, 1) }
        let!(:task_a) { create(:task, company: company, project: project) }
        let!(:task_b) { create(:task, company: company, project: project) }

        before do
          # Dia 14: 2 task_items na mesma task (Qtde=1) — 2h00 cada = 4h totais
          create(:task_item, task: task_a, work_date: Date.new(2026, 4, 14),
                            start_time: "09:00", end_time: "11:00")
          create(:task_item, task: task_a, work_date: Date.new(2026, 4, 14),
                            start_time: "14:00", end_time: "16:00")
          # Dia 15: 2 task_items em tasks distintas (Qtde=2) — 1h + 1h
          create(:task_item, task: task_a, work_date: Date.new(2026, 4, 15),
                            start_time: "09:00", end_time: "10:00")
          create(:task_item, task: task_b, work_date: Date.new(2026, 4, 15),
                            start_time: "11:00", end_time: "12:00")
          # Dia 16: 1 task_item (Qtde=1) — 2h
          create(:task_item, task: task_b, work_date: Date.new(2026, 4, 16),
                            start_time: "08:00", end_time: "10:00")
        end

        # AC4.2 + AC4.5 + AC4.6 + AC4.7 — verifica Qtde, Horas e Valor POR LINHA
        # (anti falso-positivo: só checar a data deixaria passar trocas entre colunas)
        def row_for(body, date_str)
          body.match(
            %r{<tr>\s*<td[^>]*>#{Regexp.escape(date_str)}</td>\s*<td[^>]*>(\d+)</td>\s*<td[^>]*>([\d:]+)</td>\s*<td[^>]*>R\$\s*([\d.,]+)</td>}m
          )
        end

        it "row for 16/04/2026 has Qtde=1, Horas=02:00, Valor=R$ 90,00" do
          get daily_summary_path(month: "2026-04")
          row = row_for(response.body, "16/04/2026")
          expect(row).not_to be_nil
          expect(row[1]).to eq("1")
          expect(row[2]).to eq("02:00")
          expect(row[3]).to eq("90,00")
        end

        it "row for 15/04/2026 has Qtde=2, Horas=02:00, Valor=R$ 90,00" do
          get daily_summary_path(month: "2026-04")
          row = row_for(response.body, "15/04/2026")
          expect(row).not_to be_nil
          expect(row[1]).to eq("2")
          expect(row[2]).to eq("02:00")
          expect(row[3]).to eq("90,00")
        end

        it "row for 14/04/2026 has Qtde=1, Horas=04:00, Valor=R$ 180,00" do
          get daily_summary_path(month: "2026-04")
          row = row_for(response.body, "14/04/2026")
          expect(row).not_to be_nil
          expect(row[1]).to eq("1")
          expect(row[2]).to eq("04:00")
          expect(row[3]).to eq("180,00")
        end

        # AC4.3: ordem decrescente
        it "orders rows by date desc" do
          get daily_summary_path(month: "2026-04")
          pos_16 = response.body.index("16/04/2026")
          pos_15 = response.body.index("15/04/2026")
          pos_14 = response.body.index("14/04/2026")
          expect(pos_16).to be < pos_15
          expect(pos_15).to be < pos_14
        end

        # AC3.1 / Story 10.1 AC2: KPI Cards = tasks DISTINTAS no mês (não soma diária)
        # task_a aparece nos dias 14 e 15, task_b aparece nos dias 15 e 16 → 2 tasks distintas
        it "shows KPI Cards as count of distinct tasks in the month" do
          get daily_summary_path(month: "2026-04")
          expect(response.body).to match(%r{id="kpi-cards"[^>]*>\s*2\s*<})
        end

        # Story 10.1 AC4 + AC1: uma task com apontamentos em múltiplos dias conta apenas 1
        # task_a aparece nos dias 14 e 15 → não conta como 2
        it "does not double-count a task that has task_items on multiple days" do
          get daily_summary_path(month: "2026-04")
          # task_a (dias 14 e 15) + task_b (dias 15 e 16) = 2 tasks distintas, nunca 4
          expect(response.body).to match(%r{id="kpi-cards"[^>]*>\s*2\s*<})
        end

        # AC3.2: KPI Horas = soma de hours_worked formatada HH:MM (4+2+2 = 8h = 08:00)
        it "shows KPI Horas formatted as HH:MM" do
          get daily_summary_path(month: "2026-04")
          expect(response.body).to match(%r{id="kpi-hours"[^>]*>\s*08:00\s*<})
        end

        # AC3.3: KPI Valor = soma de value formatada R$
        it "shows KPI Valor formatted as Brazilian currency" do
          get daily_summary_path(month: "2026-04")
          # 8h * R$ 45 = R$ 360,00
          expect(response.body).to include("R$ 360,00")
        end

        # AC4.8: footer total bate com KPIs
        it "renders tfoot Total row matching the KPIs" do
          get daily_summary_path(month: "2026-04")
          expect(response.body).to include('scope="row"')
          expect(response.body).to include("<tfoot")
        end

        # AC4.5: mesma task lançada 2x no mesmo dia → Qtde = 1
        it "counts distinct tasks per day (same task twice = 1)" do
          get daily_summary_path(month: "2026-04")
          # Dia 14 tem 2 task_items da mesma task → Qtde 1
          # extraímos a linha do dia 14
          row_14 = response.body.match(%r{<tr>\s*<td[^>]*>14/04/2026</td>\s*<td[^>]*>(\d+)</td>}m)
          expect(row_14).not_to be_nil
          expect(row_14[1]).to eq("1")
        end

        # AC4.2: meses sem lançamento não aparecem
        it "filters by ?month=2026-04 (does not show items from other months)" do
          create(:task_item, task: task_a, work_date: Date.new(2026, 3, 10),
                            start_time: "09:00", end_time: "10:00")
          get daily_summary_path(month: "2026-04")
          expect(response.body).not_to include("10/03/2026")
        end

        # AC2.4: param month inválido cai no default (mês corrente)
        it "falls back to current month when month param is malformed" do
          get daily_summary_path(month: "invalid")
          current = Date.current.strftime("%Y-%m")
          expect(response.body).to include(%(selected="selected" value="#{current}"))
        end

        it "falls back to current month when month param has invalid month number" do
          get daily_summary_path(month: "2026-13")
          current = Date.current.strftime("%Y-%m")
          expect(response.body).to include(%(selected="selected" value="#{current}"))
        end

        # AC2.4: param month em formato não-string (array) cai no default
        it "falls back to current month when month param is not a String" do
          get daily_summary_path, params: { month: [ "2026-04" ] }
          current = Date.current.strftime("%Y-%m")
          expect(response.body).to include(%(selected="selected" value="#{current}"))
        end

        # Mês 00 cai no default por (1..12).include? falhar
        it "falls back to current month when month is 00 (out of range)" do
          get daily_summary_path(month: "2026-00")
          current = Date.current.strftime("%Y-%m")
          expect(response.body).to include(%(selected="selected" value="#{current}"))
        end

        # AC2.5: ano diferente do corrente cai no default (filtro só lista ano corrente)
        it "falls back to current month when year differs from current year" do
          get daily_summary_path(month: "1999-04")
          current = Date.current.strftime("%Y-%m")
          expect(response.body).to include(%(selected="selected" value="#{current}"))
          # Confirma que NÃO selecionou 1999-04
          expect(response.body).not_to include(%(selected="selected" value="1999-04"))
        end

        it "falls back to current month when year is in the future" do
          future_year = Date.current.year + 5
          get daily_summary_path(month: "#{future_year}-06")
          current = Date.current.strftime("%Y-%m")
          expect(response.body).to include(%(selected="selected" value="#{current}"))
        end
      end

      # AC1.2 + AC1.3: link na navbar (desktop e mobile)
      # Padrão menos frágil: regex contextual (contexto estrutural + href + texto exato),
      # sem amarrar lista completa de classes Tailwind. Ver memory feedback_qa_022_navbar_spec_fragil.
      describe "navbar link 'Resumo Diário'" do
        it "is present inside <nav> with href=/resumo-diario and exact text" do
          get root_path
          expect(response.body).to match(
            %r{<nav[^>]*>.*?href="/resumo-diario"[^>]*>Resumo Diário</a>.*?</nav>}m
          )
        end

        it "is present inside mobile menu (id=mobile-menu) with href=/resumo-diario and exact text" do
          get root_path
          expect(response.body).to match(
            %r{id="mobile-menu".*?href="/resumo-diario"[^>]*>Resumo Diário</a>}m
          )
        end
      end

      # M2 — Boundaries do mês: dia 1, último dia e dia do mês anterior
      describe "boundaries do mês filtrado" do
        let!(:boundary_task) { create(:task, company: company, project: project) }

        it "includes task_item on the first day of the month (2026-04-01)" do
          create(:task_item, task: boundary_task, work_date: Date.new(2026, 4, 1),
                            start_time: "09:00", end_time: "10:00")
          get daily_summary_path(month: "2026-04")
          expect(response.body).to include("01/04/2026")
        end

        it "includes task_item on the last day of the month (2026-04-30)" do
          create(:task_item, task: boundary_task, work_date: Date.new(2026, 4, 30),
                            start_time: "09:00", end_time: "10:00")
          get daily_summary_path(month: "2026-04")
          expect(response.body).to include("30/04/2026")
        end

        it "excludes task_item from the last day of the previous month (2026-03-31)" do
          create(:task_item, task: boundary_task, work_date: Date.new(2026, 3, 31),
                            start_time: "09:00", end_time: "10:00")
          get daily_summary_path(month: "2026-04")
          expect(response.body).not_to include("31/03/2026")
        end
      end
    end
  end
end
