require "rails_helper"
require "ostruct"

RSpec.describe CompanyMonthlyTotalComponent, type: :component do
  def build_row(name:, hourly_rate:, total_hours:)
    OpenStruct.new(name: name, hourly_rate: hourly_rate, total_hours: total_hours)
  end

  context "com dados" do
    let(:totals) { [build_row(name: "Acme Corp", hourly_rate: 45.0, total_hours: 10.0)] }

    it "exibe o nome da empresa" do
      render_inline(described_class.new(totals: totals))
      expect(page).to have_text("Acme Corp")
    end

    it "exibe horas formatadas" do
      render_inline(described_class.new(totals: totals))
      expect(page).to have_text("10.00 h")
    end

    it "exibe valor calculado corretamente (10h * R$45 = R$450)" do
      render_inline(described_class.new(totals: totals))
      expect(page).to have_text("R$ 450,00")
    end

    it "exibe o header 'Totais do Mês por Empresa'" do
      render_inline(described_class.new(totals: totals))
      expect(page).to have_text("Totais do Mês por Empresa")
    end
  end

  context "sem dados" do
    it "exibe mensagem de sem registros" do
      render_inline(described_class.new(totals: []))
      expect(page).to have_text("Sem registros no mês")
    end
  end

  describe "#formatted_hours" do
    it "formata 1.5 como '1.50 h'" do
      component = described_class.new(totals: [])
      row = build_row(name: "X", hourly_rate: 0, total_hours: 1.5)
      expect(component.formatted_hours(row)).to eq("1.50 h")
    end
  end

  describe "#formatted_value" do
    it "calcula 8h * R$50 = R$ 400,00" do
      component = described_class.new(totals: [])
      row = build_row(name: "X", hourly_rate: 50.0, total_hours: 8.0)
      expect(component.formatted_value(row)).to eq("R$ 400,00")
    end

    it "formata corretamente valores acima de R$ 1.000 com separador de milhar" do
      component = described_class.new(totals: [])
      row = build_row(name: "X", hourly_rate: 200.0, total_hours: 10.0)
      expect(component.formatted_value(row)).to eq("R$ 2.000,00")
    end
  end
end
