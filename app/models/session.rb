# == Schema Information
#
# Table name: sessions
#
#  id         :integer          not null, primary key
#  user_id    :integer          not null
#  token      :string           not null
#  ip_address :string
#  user_agent :string
#  created_at :datetime         not null
#  updated_at :datetime         not null
#
# Indexes
#
#  index_sessions_on_token    (token) UNIQUE
#  index_sessions_on_user_id  (user_id)
#

class Session < ApplicationRecord
  belongs_to :user

  before_create :generate_token

  private

  def generate_token
    self.token = SecureRandom.urlsafe_base64
  end
end
