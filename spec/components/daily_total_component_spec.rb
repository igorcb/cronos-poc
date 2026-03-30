require "rails_helper"

RSpec.describe DailyTotalComponent, type: :component do
  it "exibe 0.00 horas quando total é zero" do
    render_inline(described_class.new(total_hours: 0))
    expect(page).to have_text("0.00 horas")
  end

  it "exibe o total com 2 casas decimais" do
    render_inline(described_class.new(total_hours: 3.5))
    expect(page).to have_text("3.50 horas")
  end

  it "exibe o label 'Total do Dia'" do
    render_inline(described_class.new(total_hours: 0))
    expect(page).to have_text("Total do Dia")
  end

  it "exibe valor inteiro formatado com .00" do
    render_inline(described_class.new(total_hours: 8))
    expect(page).to have_text("8.00 horas")
  end

  describe "#formatted_total" do
    it "formata 1.5 como '1.50 horas'" do
      component = described_class.new(total_hours: 1.5)
      expect(component.formatted_total).to eq("1.50 horas")
    end

    it "formata 0 como '0.00 horas'" do
      component = described_class.new(total_hours: 0)
      expect(component.formatted_total).to eq("0.00 horas")
    end
  end
end
