require "rails_helper"
require "ostruct"

RSpec.describe CompanyMonthlyTotalComponent, type: :component do
  def build_row(name:, hourly_rate:, total_hours:, total_minutes: (total_hours * 60).floor)
    OpenStruct.new(name: name, hourly_rate: hourly_rate, total_hours: total_hours, total_minutes: total_minutes)
  end

  context "com dados" do
    let(:totals) { [build_row(name: "Acme Corp", hourly_rate: 45.0, total_hours: 10.0, total_minutes: 600)] }

    it "exibe o nome da empresa" do
      render_inline(described_class.new(totals: totals))
      expect(page).to have_text("Acme Corp")
    end

    it "exibe horas formatadas em HH:MM" do
      render_inline(described_class.new(totals: totals))
      expect(page).to have_text("10:00")
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
    it "formata 90 minutos como '01:30'" do
      component = described_class.new(totals: [])
      row = build_row(name: "X", hourly_rate: 0, total_hours: 1.5, total_minutes: 90)
      expect(component.formatted_hours(row)).to eq("01:30")
    end

    it "formata 408 minutos como '06:48'" do
      component = described_class.new(totals: [])
      row = build_row(name: "X", hourly_rate: 0, total_hours: 6.8, total_minutes: 408)
      expect(component.formatted_hours(row)).to eq("06:48")
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
