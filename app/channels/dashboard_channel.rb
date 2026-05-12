class DashboardChannel < ActionCable::Channel::Base
  def subscribed
    stream_from "dashboard"
  end
end
