class CompanyMonthlyTotalComponent < ViewComponent::Base
  def initialize(totals:)
    @totals = totals
  end

  def formatted_hours(row)
    total_minutes = row.total_minutes.to_i
    h = total_minutes / 60
    m = total_minutes % 60
    sprintf("%02d:%02d", h, m)
  end

  def formatted_value(row)
    value = row.total_hours.to_f * row.hourly_rate.to_f
    integer_part, decimal_part = sprintf("%.2f", value).split(".")
    formatted_integer = integer_part.gsub(/(\d)(?=(\d{3})+\z)/, '\1.')
    "R$ #{formatted_integer},#{decimal_part}"
  end
end
