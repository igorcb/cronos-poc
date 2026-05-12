require "rails_helper"

RSpec.describe TaskCardComponent, type: :component do
  let(:task) { create(:task, :pending, start_date: Date.new(2026, 3, 15)) }

  it "renders a table row" do
    render_inline(described_class.new(task: task))
    expect(page).to have_css("tr")
  end

  it "displays the task name when no code is present" do
    render_inline(described_class.new(task: task))
    expect(page).to have_text(task.name)
  end

  it "displays code - name when task has a code" do
    company = create(:company)
    project = create(:project, company: company)
    task_with_code = create(:task, code: "14335", name: "Fix Bug", company: company, project: project)
    render_inline(described_class.new(task: task_with_code))
    expect(page).to have_text("14335 - Fix Bug")
  end

  it "displays the company name" do
    render_inline(described_class.new(task: task))
    expect(page).to have_text(task.company.name)
  end

  it "displays the project name" do
    render_inline(described_class.new(task: task))
    expect(page).to have_text(task.project.name)
  end

  it "displays the start_date in dd/mm/yyyy format" do
    render_inline(described_class.new(task: task))
    expect(page).to have_text("15/03/2026")
  end

  it "renders the status badge with correct CSS class for pending" do
    task = create(:task, :pending)
    render_inline(described_class.new(task: task))
    expect(page).to have_css("span.bg-yellow-900")
  end

  it "renders the status badge with correct CSS class for completed" do
    task = create(:task, :completed)
    render_inline(described_class.new(task: task))
    expect(page).to have_css("span.bg-green-900")
  end

  it "renders the status badge with correct CSS class for delivered" do
    task = create(:task, :delivered)
    render_inline(described_class.new(task: task))
    expect(page).to have_css("span.bg-blue-900")
  end

  it "displays estimated_hours_hm" do
    render_inline(described_class.new(task: task))
    expect(page).to have_text(task.estimated_hours_hm)
  end

  it "displays 00:00 for validated_hours when task has no task_items" do
    task = create(:task, code: "99999")
    task.reload
    render_inline(described_class.new(task: task))
    expect(page).to have_text("00:00")
    expect(page).not_to have_css("td", text: "-", exact_text: true)
  end

  it "displays validated_hours in HH:MM format when task has task_items" do
    task = create(:task)
    create(:task_item, :completed, task: task)
    task.reload
    render_inline(described_class.new(task: task))
    expect(page).to have_text(task.validated_hours_hm)
  end

  describe "display_value — coluna Valor" do
    let(:company) { create(:company, hourly_rate: 100) }
    let(:project) { create(:project, company: company) }

    it "exibe R$0,00 quando task sem lançamentos (não entregue)" do
      task_sem_items = create(:task, company: company, project: project)
      render_inline(described_class.new(task: task_sem_items))
      expect(page).to have_text("R$0,00")
    end

    it "exibe total_value quando task não entregue com lançamentos" do
      task_com_items = create(:task, company: company, project: project)
      create(:task_item, task: task_com_items, start_time: "09:00", end_time: "10:00")
      task_com_items.reload
      render_inline(described_class.new(task: task_com_items))
      expect(page).to have_text("R$100,00")
    end

    it "exibe total_value para task com código e lançamentos (não entregue)" do
      task_com_code = create(:task, code: "42", name: "Task Valor", company: company, project: project)
      create(:task_item, task: task_com_code, start_time: "09:00", end_time: "10:30")
      task_com_code.reload
      render_inline(described_class.new(task: task_com_code))
      expect(page).to have_text("R$150,00")
    end

    it "exibe delivered_value (snapshot) quando task entregue" do
      task_entregue = create(:task, company: company, project: project)
      create(:task_item, task: task_entregue, start_time: "09:00", end_time: "10:00")
      task_entregue.update!(status: "completed")
      task_entregue.update!(status: "delivered")
      task_entregue.reload
      render_inline(described_class.new(task: task_entregue))
      expect(page).to have_text("R$100,00")
    end
  end

  def number_with_precision(number, precision:)
    sprintf("%.#{precision}f", number)
  end
end
