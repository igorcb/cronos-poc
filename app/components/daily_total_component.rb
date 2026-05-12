class DailyTotalComponent < ViewComponent::Base
  def initialize(total_minutes:)
    @total_minutes = total_minutes.to_i
  end

  def formatted_total
    h = @total_minutes / 60
    m = @total_minutes % 60
    sprintf("%02d:%02d", h, m)
  end
end
