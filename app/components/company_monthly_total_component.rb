class CompanyMonthlyTotalComponent < ViewComponent::Base
  def initialize(totals:)
    @totals = totals
  end

  def formatted_hours(row)
    "#{sprintf('%.2f', row.total_hours.to_f)} h"
  end

  def formatted_value(row)
    value = row.total_hours.to_f * row.hourly_rate.to_f
    integer_part, decimal_part = sprintf("%.2f", value).split(".")
    formatted_integer = integer_part.gsub(/(\d)(?=(\d{3})+\z)/, '\1.')
    "R$ #{formatted_integer},#{decimal_part}"
  end
end
