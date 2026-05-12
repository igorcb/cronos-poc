module ApplicationHelper
  # Converte minutos inteiros (calculados via SQL EXTRACT) para HH:MM.
  # Evita acúmulo de erro de arredondamento de conversões float intermediárias.
  def minutes_to_hm(total_minutes)
    total_minutes = total_minutes.to_i
    h = total_minutes / 60
    m = total_minutes % 60
    sprintf("%02d:%02d", h, m)
  end

  def hours_to_hm(decimal_hours)
    total_minutes = (decimal_hours.to_f * 60).floor
    h = total_minutes / 60
    m = total_minutes % 60
    sprintf("%02d:%02d", h, m)
  end
end
