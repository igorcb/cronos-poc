class Current < ActiveSupport::CurrentAttributes
  attribute :session
  # user_override: usado em background jobs (DashboardBroadcastJob) para setar
  # o tenant atual sem precisar de Session real (story 9.2 QA #3, #21).
  attribute :user_override

  def user
    user_override || session&.user
  end
end
