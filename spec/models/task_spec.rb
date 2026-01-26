# == Schema Information
#
# Table name: tasks
#
#  id              :integer          not null, primary key
#  name            :string           not null
#  company_id      :integer          not null
#  project_id      :integer          not null
#  start_date      :date             not null
#  end_date        :date
#  status          :string           default("pending"), not null
#  delivery_date   :date
#  estimated_hours :decimal(10, 2)   not null
#  validated_hours :decimal(10, 2)
#  notes           :text
#  created_at      :datetime         not null
#  updated_at      :datetime         not null
#
# Indexes
#
#  index_tasks_on_company_id              (company_id)
#  index_tasks_on_project_id              (project_id)
#  index_tasks_on_status                  (status)
#  index_tasks_on_company_id_and_project_id  (company_id, project_id)
#
# Foreign Keys
#
#  fk_rails_...  company_id (company_id => companies.id)
#  fk_rails_...  project_id (project_id => projects.id)
#

require 'rails_helper'

RSpec.describe Task, type: :model do
  describe "validations" do
    let(:company) { create(:company) }
    let(:project) { create(:project, company: company) }

    it "is valid with valid attributes" do
      task = build(:task, company: company, project: project)
      expect(task).to be_valid
    end

    it "requires a name" do
      task = build(:task, name: nil, company: company, project: project)
      expect(task).not_to be_valid
      expect(task.errors[:name]).to include("não pode ficar em branco")
    end

    it "requires a company" do
      task = build(:task, company: nil, project: project)
      expect(task).not_to be_valid
      expect(task.errors[:company]).to be_present
    end

    it "requires a project" do
      task = build(:task, company: company, project: nil)
      expect(task).not_to be_valid
      expect(task.errors[:project]).to be_present
    end

    it "requires a start_date" do
      task = build(:task, start_date: nil, company: company, project: project)
      expect(task).not_to be_valid
      expect(task.errors[:start_date]).to include("não pode ficar em branco")
    end

    it "requires estimated_hours" do
      task = build(:task, estimated_hours: nil, company: company, project: project)
      expect(task).not_to be_valid
      expect(task.errors[:estimated_hours]).to include("não pode ficar em branco")
    end

    it "requires estimated_hours to be greater than 0" do
      task = build(:task, estimated_hours: 0, company: company, project: project)
      expect(task).not_to be_valid
      expect(task.errors[:estimated_hours]).to include("deve ser maior que 0")
    end

    it "rejects negative estimated_hours" do
      task = build(:task, estimated_hours: -10, company: company, project: project)
      expect(task).not_to be_valid
      expect(task.errors[:estimated_hours]).to include("deve ser maior que 0")
    end

    it "requires status to be valid" do
      task = build(:task, company: company, project: project)

      expect { task.status = 'invalid_status' }.to raise_error(ArgumentError)
    end

    it "allows valid status values" do
      %w[pending completed delivered].each do |status|
        task = build(:task, status: status, company: company, project: project)
        expect(task).to be_valid
      end
    end

    describe "#project_must_belong_to_company" do
      it "validates when project belongs to the same company" do
        task = build(:task, company: company, project: project)
        expect(task).to be_valid
      end

      it "adds error when project belongs to different company" do
        other_company = create(:company)
        other_project = create(:project, company: other_company)
        task = build(:task, company: company, project: other_project)

        expect(task).not_to be_valid
        expect(task.errors[:project]).to include("deve pertencer à mesma empresa")
      end
    end
  end

  describe "enums" do
    let(:company) { create(:company) }
    let(:project) { create(:project, company: company) }

    it "defines status enum" do
      task = create(:task, company: company, project: project, status: 'pending')

      expect(task.pending?).to be true
      expect(task.completed?).to be false
      expect(task.delivered?).to be false
    end

    it "transitions status correctly" do
      task = create(:task, :pending, company: company, project: project)

      task.update(status: 'completed')
      expect(task.completed?).to be true
      expect(task.pending?).to be false

      task.update(status: 'delivered')
      expect(task.delivered?).to be true
      expect(task.completed?).to be false
    end
  end

  describe "scopes" do
    let(:company) { create(:company) }
    let(:project) { create(:project, company: company) }

    before do
      create(:task, :pending, company: company, project: project)
      create(:task, :completed, company: company, project: project)
      create(:task, :delivered, company: company, project: project)
    end

    describe ".by_status" do
      it "returns tasks for specific status" do
        pending_tasks = Task.by_status('pending')
        expect(pending_tasks.count).to eq(1)
        expect(pending_tasks.first.pending?).to be true

        completed_tasks = Task.by_status('completed')
        expect(completed_tasks.count).to eq(1)
        expect(completed_tasks.first.completed?).to be true
      end
    end

    describe ".by_company" do
      it "returns tasks for specific company" do
        other_company = create(:company)
        other_project = create(:project, company: other_company)
        create(:task, company: other_company, project: other_project)

        company_tasks = Task.by_company(company.id)
        expect(company_tasks.count).to eq(3)
        expect(company_tasks.pluck(:company_id).uniq).to eq([ company.id ])
      end
    end

    describe ".by_project" do
      it "returns tasks for specific project" do
        other_project = create(:project, company: company)
        create(:task, company: company, project: other_project)

        project_tasks = Task.by_project(project.id)
        expect(project_tasks.count).to eq(3)
        expect(project_tasks.pluck(:project_id).uniq).to eq([ project.id ])
      end
    end
  end

  describe "associations" do
    let(:company) { create(:company) }
    let(:project) { create(:project, company: company) }

    it "belongs to company" do
      task = create(:task, company: company, project: project)
      expect(task.company).to eq(company)
    end

    it "belongs to project" do
      task = create(:task, company: company, project: project)
      expect(task.project).to eq(project)
    end

    it "has many task_items" do
      task = create(:task, company: company, project: project)
      expect(task).to respond_to(:task_items)
    end
  end

  describe "default values" do
    let(:company) { create(:company) }
    let(:project) { create(:project, company: company) }

    it "defaults status to pending" do
      task = Task.new(
        name: "Test Task",
        company: company,
        project: project,
        start_date: Date.today,
        estimated_hours: 40
      )
      expect(task.status).to eq('pending')
    end
  end

  describe "decimal precision" do
    let(:company) { create(:company) }
    let(:project) { create(:project, company: company) }

    it "stores estimated_hours as BigDecimal" do
      task = create(:task, company: company, project: project, estimated_hours: 40.50)
      expect(task.estimated_hours).to be_a(BigDecimal)
    end

    it "maintains decimal precision for estimated_hours" do
      task = create(:task, company: company, project: project, estimated_hours: 39.99)
      expect(task.reload.estimated_hours).to eq(BigDecimal("39.99"))
    end

    it "stores validated_hours as BigDecimal" do
      task = create(:task, company: company, project: project, validated_hours: 38.75)
      expect(task.validated_hours).to be_a(BigDecimal)
    end

    it "maintains decimal precision for validated_hours" do
      task = create(:task, company: company, project: project)
      create(:task_item, task: task, start_time: "09:00", end_time: "12:30")
      task.reload

      expect(task.validated_hours).to be_a(BigDecimal)
      expect(task.validated_hours.to_f).to eq(3.5)
    end
  end

  describe "optional fields" do
    let(:company) { create(:company) }
    let(:project) { create(:project, company: company) }

    it "allows nil end_date" do
      task = build(:task, :without_end_date, company: company, project: project)
      expect(task).to be_valid
      expect(task.end_date).to be_nil
    end

    it "allows nil validated_hours" do
      task = build(:task, :without_validated_hours, company: company, project: project)
      expect(task).to be_valid
      expect(task.validated_hours).to be_nil
    end

    it "allows nil delivery_date" do
      task = build(:task, :without_delivery_date, company: company, project: project)
      expect(task).to be_valid
      expect(task.delivery_date).to be_nil
    end

    it "allows nil notes" do
      task = build(:task, notes: nil, company: company, project: project)
      expect(task).to be_valid
      expect(task.notes).to be_nil
    end

    it "accepts notes when provided" do
      task = build(:task, :with_notes, company: company, project: project)
      expect(task).to be_valid
      expect(task.notes).to be_present
    end
  end

  describe "#total_hours" do
    let(:company) { create(:company, hourly_rate: 100) }
    let(:project) { create(:project, company: company) }
    let(:task) { create(:task, company: company, project: project) }

    it "returns 0 when no task_items exist" do
      expect(task.total_hours).to eq(0)
    end

    it "sums hours_worked from all task_items" do
      create(:task_item, task: task, start_time: "09:00", end_time: "10:30", hours_worked: 1.5)
      create(:task_item, task: task, start_time: "14:00", end_time: "16:00", hours_worked: 2.0)
      create(:task_item, task: task, start_time: "16:00", end_time: "18:30", hours_worked: 2.5)

      expect(task.total_hours).to eq(6.0)
    end
  end

  describe "#calculated_value" do
    let(:company) { create(:company, hourly_rate: 100) }
    let(:project) { create(:project, company: company) }
    let(:task) { create(:task, company: company, project: project) }

    it "calculates total_hours * hourly_rate" do
      create(:task_item, task: task, start_time: "09:00", end_time: "10:30", hours_worked: 1.5)
      create(:task_item, task: task, start_time: "14:00", end_time: "16:00", hours_worked: 2.0)

      expect(task.calculated_value).to eq(350.0) # 3.5 hours * 100
    end
  end

  describe "#recalculate_status!" do
    let(:company) { create(:company) }
    let(:project) { create(:project, company: company) }
    let(:task) { create(:task, company: company, project: project, status: "pending") }

    context "when task is delivered" do
      it "does not recalculate status" do
        task.update!(status: "delivered")

        expect { task.recalculate_status! }.not_to change(task, :status)
        expect(task.status).to eq("delivered")
      end
    end

    context "when no task_items exist" do
      it "does not change status" do
        expect { task.recalculate_status! }.not_to change(task, :status)
        expect(task.status).to eq("pending")
      end
    end

    context "when latest task_item is pending" do
      it "keeps task status as pending" do
        create(:task_item, :completed, task: task, created_at: 1.day.ago)
        create(:task_item, :pending, task: task, created_at: Date.today)

        task.recalculate_status!
        expect(task.reload.status).to eq("pending")
      end
    end

    context "when latest task_item is completed" do
      it "sets task status to completed" do
        pending_item = create(:task_item, :pending, task: task, created_at: 1.day.ago)
        task.reload
        expect(task.status).to eq("pending")

        completed_item = create(:task_item, :completed, task: task, created_at: Date.today)
        task.reload
        expect(task.status).to eq("completed")
      end
    end
  end

  describe "callbacks" do
    let(:company) { create(:company) }
    let(:project) { create(:project, company: company) }
    let(:task) { create(:task, company: company, project: project) }

    describe "#update_end_date" do
      it "sets end_date when status changes to completed" do
        task.update!(status: "completed")
        expect(task.end_date).to eq(Date.today)
      end

      it "does not change end_date when status changes from completed to delivered" do
        task.update!(status: "completed")
        original_end_date = task.end_date
        task.update!(status: "delivered")

        expect(task.end_date).to eq(original_end_date)
      end
    end

    describe "#update_delivery_date" do
      it "sets delivery_date when status changes to delivered" do
        task.update!(status: "delivered")
        expect(task.delivery_date).to eq(Date.today)
      end
    end

    describe "#recalculate_validated_hours" do
      it "updates validated_hours after task_items are created" do
        create(:task_item, task: task, start_time: "09:00", end_time: "10:30")
        create(:task_item, task: task, start_time: "14:00", end_time: "16:00")

        task.reload
        expect(task.validated_hours.to_f).to eq(3.5)
      end
    end
  end
end
