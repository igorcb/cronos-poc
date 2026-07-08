require "rails_helper"

RSpec.describe IdlePeriod, type: :model do
  it "is valid with valid attributes" do
    idle_period = build(:idle_period)
    expect(idle_period).to be_valid
  end

  it "requires start_time" do
    idle_period = build(:idle_period, start_time: nil)
    expect(idle_period).not_to be_valid
  end

  it "requires end_time" do
    idle_period = build(:idle_period, end_time: nil)
    expect(idle_period).not_to be_valid
  end

  it "requires work_date" do
    idle_period = build(:idle_period, work_date: nil)
    expect(idle_period).not_to be_valid
  end

  it "is invalid when end_time is not after start_time" do
    idle_period = build(:idle_period, start_time: "10:00", end_time: "09:00")
    expect(idle_period).not_to be_valid
    expect(idle_period.errors[:end_time]).to include("deve ser posterior à hora inicial")
  end

  it "is invalid when end_time equals start_time" do
    idle_period = build(:idle_period, start_time: "09:00", end_time: "09:00")
    expect(idle_period).not_to be_valid
    expect(idle_period.errors[:end_time]).to include("deve ser posterior à hora inicial")
  end

  it "calculates hours on save" do
    idle_period = create(:idle_period, start_time: "09:00", end_time: "11:00")
    expect(idle_period.hours).to eq(2.0)
  end

  it "calculates hours for long_duration trait" do
    idle_period = create(:idle_period, :long_duration)
    expect(idle_period.hours).to eq(4.0)
  end

  it "does not allow changing user_id after create" do
    idle_period = create(:idle_period)
    other_user = create(:user)

    expect { idle_period.user_id = other_user.id }
      .to raise_error(ActiveRecord::ReadonlyAttributeError)
  end

  describe ".by_user_and_month" do
    it "returns idle periods for the user within the given month" do
      user = create(:user)
      in_month = create(:idle_period, user:, work_date: Date.current)
      create(:idle_period, user:, work_date: 2.months.ago)

      result = described_class.by_user_and_month(user, Date.current)

      expect(result).to contain_exactly(in_month)
    end

    it "does not return idle periods from another user" do
      user = create(:user)
      other_user = create(:user)
      create(:idle_period, user: other_user, work_date: Date.current)

      result = described_class.by_user_and_month(user, Date.current)

      expect(result).to be_empty
    end
  end
end
