class DailySummaryController < ApplicationController
  def index
    @selected_month = sanitize_month_param(params[:month])
    year, month = @selected_month.split("-").map(&:to_i)
    @month_range = Date.new(year, month, 1).all_month
    @selected_month_label = I18n.t("date.month_names")[month]

    @daily_rows = TaskItem
      .where(work_date: @month_range)
      .group(:work_date)
      .order(work_date: :desc)
      .pluck(
        :work_date,
        Arel.sql("COUNT(DISTINCT task_id)"),
        Arel.sql("SUM(hours_worked)"),
        Arel.sql("SUM(value)")
      )
      .map { |date, qtde, hours, value| [date, qtde.to_i, hours.to_f, value.to_f] }

    @kpi_cards = @daily_rows.sum { |_, qtde, _, _| qtde }
    @kpi_hours = @daily_rows.sum { |_, _, hours, _| hours }
    @kpi_value = @daily_rows.sum { |_, _, _, value| value }

    current_year = Date.current.year
    @month_options = (1..12).map do |m|
      [I18n.t("date.month_names")[m], "#{current_year}-#{m.to_s.rjust(2, '0')}"]
    end
  end

  private

  def sanitize_month_param(raw)
    default = Date.current.strftime("%Y-%m")
    return default if raw.blank?
    return default unless raw.is_a?(String) && raw.match?(/\A\d{4}-\d{2}\z/)

    year, month = raw.split("-").map(&:to_i)
    return default unless (1..12).include?(month)
    return default unless year == Date.current.year

    raw
  end
end
