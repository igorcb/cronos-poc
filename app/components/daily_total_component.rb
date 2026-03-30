class DailyTotalComponent < ViewComponent::Base
  def initialize(total_hours:)
    @total_hours = total_hours
  end

  def formatted_total
    "#{sprintf('%.2f', @total_hours)} horas"
  end
end
