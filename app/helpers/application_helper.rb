module ApplicationHelper
  def hours_to_hm(decimal_hours)
    total_minutes = (decimal_hours.to_f * 60).round
    h = total_minutes / 60
    m = total_minutes % 60
    sprintf("%d:%02d", h, m)
  end
end
