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

  it "displays 0.00 for validated_hours when task has no task_items" do
    task = create(:task, code: "99999")
    task.reload
    render_inline(described_class.new(task: task))
    # after_save :recalculate_validated_hours sets validated_hours to 0.0 (not nil)
    # so .present? is truthy and we get "0.00", not "-"
    expect(page).to have_text("0.00")
    expect(page).not_to have_css("td", text: "-", exact_text: true)
  end

  it "displays validated_hours value when task has task_items" do
    task = create(:task)
    create(:task_item, :completed, task: task)
    task.reload
    render_inline(described_class.new(task: task))
    expect(page).to have_text(number_with_precision(task.validated_hours, precision: 2))
  end

  it "displays calculated_value with R$ currency" do
    render_inline(described_class.new(task: task))
    expect(page).to have_text("R$")
  end

  def number_with_precision(number, precision:)
    format("%.#{precision}f", number)
  end
end
