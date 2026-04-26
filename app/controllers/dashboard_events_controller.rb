class DashboardEventsController < ApplicationController
  include ActionController::Live
  include DashboardCalculations

  POLL_INTERVAL = 1 # segundo

  def events
    response.headers["Content-Type"]      = "text/event-stream"
    response.headers["Cache-Control"]     = "no-cache"
    response.headers["X-Accel-Buffering"] = "no"

    sse       = SSE.new(response.stream, retry: 2000)
    last_seen = current_fingerprint

    sse.write({ connected: true }, event: "ping")

    loop do
      sleep POLL_INTERVAL
      now = current_fingerprint
      if now != last_seen
        last_seen = now
        sse.write(render_streams, event: "dashboard-update")
      end
    end
  rescue ActionController::Live::ClientDisconnected, IOError
    # cliente desconectou
  ensure
    sse.close
  end

  def refresh
    render "dashboard/streams", locals: stream_locals
  end

  private

  # Fingerprint baseado no updated_at mais recente de tasks e task_items do mês
  def current_fingerprint
    task_ts = Task.where(start_date: Date.current.all_month).maximum(:updated_at)
    item_ts  = TaskItem.joins(:task)
                       .where(tasks: { start_date: Date.current.all_month })
                       .maximum(:updated_at)
    [ task_ts, item_ts ].compact.max
  end

  def stream_locals
    {
      daily_hours:        calculate_daily_hours,
      monthly_hours:      calculate_monthly_hours,
      monthly_value:      calculate_monthly_value,
      daily_task_count:   calculate_daily_task_count,
      monthly_task_count: calculate_monthly_task_count,
      daily_value:        calculate_daily_value,
      tasks:              monthly_tasks
    }
  end

  def render_streams
    render_to_string(formats: [:turbo_stream], template: "dashboard/streams", locals: stream_locals)
  end
end
