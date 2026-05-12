require "rails_helper"

RSpec.describe DailyTotalComponent, type: :component do
  it "exibe 00:00 quando total é zero" do
    render_inline(described_class.new(total_minutes: 0))
    expect(page).to have_text("00:00")
  end

  it "exibe o total no formato HH:MM" do
    render_inline(described_class.new(total_minutes: 210))
    expect(page).to have_text("03:30")
  end

  it "exibe o label 'Total do Dia'" do
    render_inline(described_class.new(total_minutes: 0))
    expect(page).to have_text("Total do Dia")
  end

  it "exibe 8 horas exatas como 08:00" do
    render_inline(described_class.new(total_minutes: 480))
    expect(page).to have_text("08:00")
  end

  describe "#formatted_total" do
    it "formata 90 minutos como '01:30'" do
      component = described_class.new(total_minutes: 90)
      expect(component.formatted_total).to eq("01:30")
    end

    it "formata 0 como '00:00'" do
      component = described_class.new(total_minutes: 0)
      expect(component.formatted_total).to eq("00:00")
    end

    it "formata 408 minutos (06:48) corretamente" do
      component = described_class.new(total_minutes: 408)
      expect(component.formatted_total).to eq("06:48")
    end
  end
end
