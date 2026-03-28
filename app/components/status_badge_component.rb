class StatusBadgeComponent < ViewComponent::Base
  attr_reader :status

  def initialize(status:)
    @status = status
  end

  def badge_classes
    base = "inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-medium"
    color = case status
    when "pending"   then "bg-yellow-900 text-yellow-300 border border-yellow-700"
    when "completed" then "bg-green-900 text-green-300 border border-green-700"
    when "delivered" then "bg-blue-900 text-blue-300 border border-blue-700"
    else                  "bg-gray-700 text-gray-300 border border-gray-600"
    end
    "#{base} #{color}"
  end
end
