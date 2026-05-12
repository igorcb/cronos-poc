require "rails_helper"

RSpec.describe StatusBadgeComponent, type: :component do
  describe "#badge_classes" do
    it "returns yellow classes for pending status" do
      component = described_class.new(status: "pending")
      expect(component.badge_classes).to include("bg-yellow-900", "text-yellow-300", "border-yellow-700")
    end

    it "returns green classes for completed status" do
      component = described_class.new(status: "completed")
      expect(component.badge_classes).to include("bg-green-900", "text-green-300", "border-green-700")
    end

    it "returns blue classes for delivered status" do
      component = described_class.new(status: "delivered")
      expect(component.badge_classes).to include("bg-blue-900", "text-blue-300", "border-blue-700")
    end

    it "returns gray classes for unknown status" do
      component = described_class.new(status: "unknown")
      expect(component.badge_classes).to include("bg-gray-700", "text-gray-300", "border-gray-600")
    end

    it "includes base inline-flex classes" do
      component = described_class.new(status: "pending")
      expect(component.badge_classes).to include("inline-flex", "items-center", "rounded-full")
    end
  end

  describe "rendering" do
    it "renders a span with capitalized status text for pending" do
      render_inline(described_class.new(status: "pending"))
      expect(page).to have_css("span", text: "Pending")
    end

    it "renders a span with capitalized status text for completed" do
      render_inline(described_class.new(status: "completed"))
      expect(page).to have_css("span", text: "Completed")
    end

    it "renders a span with capitalized status text for delivered" do
      render_inline(described_class.new(status: "delivered"))
      expect(page).to have_css("span", text: "Delivered")
    end

    it "renders with yellow classes for pending" do
      render_inline(described_class.new(status: "pending"))
      expect(page).to have_css("span.bg-yellow-900")
    end

    it "renders with green classes for completed" do
      render_inline(described_class.new(status: "completed"))
      expect(page).to have_css("span.bg-green-900")
    end

    it "renders with blue classes for delivered" do
      render_inline(described_class.new(status: "delivered"))
      expect(page).to have_css("span.bg-blue-900")
    end

    it "renders with gray fallback for unknown status" do
      render_inline(described_class.new(status: "anything"))
      expect(page).to have_css("span.bg-gray-700")
    end
  end
end
