require 'rails_helper'

RSpec.describe TaskItem, type: :model do
  describe "validations" do
    let(:task) { create(:task) }

    it "is valid with valid attributes" do
      task_item = build(:task_item, task: task)
      expect(task_item).to be_valid
    end

    it "requires a task" do
      task_item = build(:task_item, task: nil)
      expect(task_item).not_to be_valid
      expect(task_item.errors[:task]).to be_present
    end

    it "requires start_time" do
      task_item = build(:task_item, task: task, start_time: nil)
      expect(task_item).not_to be_valid
      expect(task_item.errors[:start_time]).to include("não pode ficar em branco")
    end

    it "requires end_time" do
      task_item = build(:task_item, task: task, end_time: nil)
      expect(task_item).not_to be_valid
      expect(task_item.errors[:end_time]).to include("não pode ficar em branco")
    end

    it "requires status to be valid" do
      task_item = build(:task_item, task: task)

      expect { task_item.status = 'invalid_status' }.to raise_error(ArgumentError)
    end

    it "allows valid status values" do
      %w[pending completed].each do |status|
        task_item = build(:task_item, task: task, status: status)
        expect(task_item).to be_valid
      end
    end

    describe "#end_time_after_start_time" do
      it "validates when end_time is after start_time" do
        task_item = build(:task_item, task: task, start_time: '09:00', end_time: '10:30')
        expect(task_item).to be_valid
      end

      it "adds error when end_time equals start_time" do
        task_item = build(:task_item, task: task, start_time: '09:00', end_time: '09:00')
        expect(task_item).not_to be_valid
        expect(task_item.errors[:end_time]).to include("deve ser posterior à hora inicial")
      end

      it "adds error when end_time is before start_time" do
        task_item = build(:task_item, task: task, start_time: '10:30', end_time: '09:00')
        expect(task_item).not_to be_valid
        expect(task_item.errors[:end_time]).to include("deve ser posterior à hora inicial")
      end

      it "skips validation when times are missing" do
        task_item = build(:task_item, task: task, start_time: nil, end_time: nil)
        task_item.valid?
        expect(task_item.errors[:end_time]).not_to include("deve ser posterior à hora inicial")
      end
    end

    describe "#task_must_not_be_delivered" do
      let(:delivered_task) { create(:task, :delivered) }

      it "adds error when task is delivered on create" do
        task_item = build(:task_item, task: delivered_task)
        expect(task_item).not_to be_valid
        expect(task_item.errors[:base]).to include("Não é possível modificar itens de tarefa já entregue")
      end

      it "adds error when task is delivered on update" do
        task_item = create(:task_item, task: task)
        task.update!(status: 'delivered')

        task_item.update(status: 'completed')
        expect(task_item).not_to be_valid
        expect(task_item.errors[:base]).to include("Não é possível modificar itens de tarefa já entregue")
      end

      it "prevents destroy when task is delivered" do
        task_item = create(:task_item, task: task)
        task.update!(status: 'delivered')

        result = task_item.destroy
        expect(result).to be_falsey
        expect(task_item.errors[:base]).to include("Não é possível modificar itens de tarefa já entregue")
        # TaskItem ainda deve existir no banco
        expect(TaskItem.find_by(id: task_item.id)).not_to be_nil
      end

      it "allows modifications when task is not delivered" do
        task_item = build(:task_item, task: task)
        expect(task_item).to be_valid
      end

      it "skips validation when task is nil" do
        task_item = build(:task_item, task: nil)
        task_item.valid?
        expect(task_item.errors[:base]).not_to include("Não é possível modificar itens de tarefa já entregue")
      end
    end
  end

  describe "associations" do
    it "belongs to task" do
      association = described_class.reflect_on_association(:task)
      expect(association.macro).to eq(:belongs_to)
    end
  end

  describe "enums" do
    let(:task) { create(:task) }

    it "defines status enum" do
      task_item = create(:task_item, task: task)
      expect(task_item).to respond_to(:pending?)
      expect(task_item).to respond_to(:completed?)
    end

    it "has pending status" do
      task_item = create(:task_item, :pending, task: task)
      expect(task_item.status).to eq('pending')
      expect(task_item).to be_pending
    end

    it "has completed status" do
      task_item = create(:task_item, :completed, task: task)
      expect(task_item.status).to eq('completed')
      expect(task_item).to be_completed
    end
  end

  describe "callbacks" do
    let(:task) { create(:task) }

    describe "#calculate_hours_worked" do
      it "calculates hours_worked before save" do
        task_item = build(:task_item, task: task, start_time: '09:00', end_time: '10:30')
        expect { task_item.save }.to change(task_item, :hours_worked).from(nil).to(1.5)
      end

      it "correctly calculates 1.5 hours for 09:00 to 10:30" do
        task_item = create(:task_item, task: task, start_time: '09:00', end_time: '10:30')
        expect(task_item.hours_worked).to eq(1.5)
      end

      it "correctly calculates 4.25 hours for 08:00 to 12:15" do
        task_item = create(:task_item, task: task, start_time: '08:00', end_time: '12:15')
        expect(task_item.hours_worked).to eq(4.25)
      end

      it "correctly calculates 10.5 hours for long duration" do
        task_item = create(:task_item, :long_duration, task: task)
        expect(task_item.hours_worked).to eq(10.5)
      end

      it "correctly calculates 0.5 hours for short duration" do
        task_item = create(:task_item, :short_duration, task: task)
        expect(task_item.hours_worked).to eq(0.5)
      end

      it "rounds to 2 decimal places" do
        task_item = create(:task_item, task: task, start_time: '09:00', end_time: '10:17')
        # 10:17 - 09:00 = 1h 17min = 77 minutes = 1.28333... hours
        expect(task_item.hours_worked).to eq(1.28)
      end

      it "does not calculate when times are missing" do
        task_item = build(:task_item, task: task, start_time: nil, end_time: nil)
        task_item.save
        expect(task_item.hours_worked).to be_nil
      end
    end

    describe "#update_task_status" do
      it "is called after save" do
        task_item = build(:task_item, task: task)
        expect(task_item).to receive(:update_task_status).and_call_original
        task_item.save
      end

      it "is called after destroy" do
        task_item = create(:task_item, task: task)
        expect(task_item).to receive(:update_task_status).and_call_original
        task_item.destroy
      end

      # NOTE: Full integration test with recalculate_status! will be in Story 4.3
      it "returns early when task is nil" do
        task_item = build(:task_item, task: nil)
        expect { task_item.save }.not_to raise_error
      end
    end
  end

  describe "scopes" do
    let(:task) { create(:task) }
    let(:task2) { create(:task) }

    before do
      create(:task_item, :pending, task: task, created_at: 1.day.ago)
      create(:task_item, :completed, task: task, created_at: 2.days.ago)
      create(:task_item, :pending, task: task2, created_at: 3.days.ago)
    end

    describe ".by_task" do
      it "returns task_items for specific task" do
        task_items = TaskItem.by_task(task.id)
        expect(task_items.count).to eq(2)
        expect(task_items.all? { |ti| ti.task_id == task.id }).to be true
      end

      it "does not return task_items from other tasks" do
        task_items = TaskItem.by_task(task.id)
        expect(task_items.none? { |ti| ti.task_id == task2.id }).to be true
      end
    end

    describe ".recent_first" do
      it "orders by created_at descending" do
        task_items = TaskItem.recent_first
        expect(task_items.first.created_at).to be > task_items.last.created_at
      end
    end
  end

  describe "database constraints" do
    let(:task) { create(:task) }

    it "saves with valid data" do
      task_item = build(:task_item, task: task)
      expect { task_item.save }.to change(TaskItem, :count).by(1)
    end
  end

  describe "#update_task_status callback" do
    let(:task) { create(:task, status: "pending") }

    context "when task_item is created" do
      it "recalculates task status to pending when task_item is pending" do
        create(:task_item, :pending, task: task)
        task.reload

        expect(task.status).to eq("pending")
      end

      it "recalculates task status to completed when task_item is completed" do
        create(:task_item, :completed, task: task)
        task.reload

        expect(task.status).to eq("completed")
      end
    end

    context "when task_item is updated" do
      it "recalculates task status when task_item changes from pending to completed" do
        task_item = create(:task_item, :pending, task: task)
        task_item.update!(status: "completed")
        task.reload

        expect(task.status).to eq("completed")
      end

      it "recalculates task status when task_item changes from completed to pending" do
        task.update!(status: "completed")
        task_item = create(:task_item, :completed, task: task, created_at: 1.day.ago)
        new_item = create(:task_item, :pending, task: task)

        task.reload
        expect(task.status).to eq("pending")
      end
    end

    context "when task_item is destroyed" do
      it "recalculates task status when latest task_item is deleted" do
        completed_item = create(:task_item, :completed, task: task, created_at: 1.day.ago)
        pending_item = create(:task_item, :pending, task: task, created_at: Date.today)

        expect(task.status).to eq("pending")

        pending_item.destroy
        task.reload

        expect(task.status).to eq("completed")
      end
    end

    context "when task is delivered" do
      it "prevents creating new task_items" do
        task.update!(status: "delivered")

        expect {
          create(:task_item, :completed, task: task)
        }.to raise_error(ActiveRecord::RecordInvalid)
      end
    end
  end
end
