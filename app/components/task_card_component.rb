class TaskCardComponent < ViewComponent::Base
  attr_reader :task

  def initialize(task:)
    @task = task
  end
end
