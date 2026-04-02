class TasksController < ApplicationController
  before_action :require_authentication
  before_action :set_task, only: [ :edit, :update, :destroy ]

  def index
    @tasks = Task
      .includes(:company, :project, :task_items)
      .where(start_date: Date.current.all_month)
      .order(start_date: :desc, created_at: :desc)

    company_id = params[:company_id].present? ? params[:company_id].to_i : nil
    project_id = params[:project_id].present? ? params[:project_id].to_i : nil

    @tasks = @tasks.by_company(company_id) if company_id
    @tasks = @tasks.by_project(project_id) if project_id

    @daily_total = calculate_daily_total(@tasks)
    @company_monthly_totals = calculate_company_totals(@tasks)

    @companies = Company.active.order(:name)
    @projects = company_id ?
      Project.where(company_id: company_id).order(:name) :
      Project.joins(:company).merge(Company.active).order(:name)
  end

  def new
    @task = Task.new
    @companies = Company.active.order(:name)
  end

  def create
    @task = Task.new(task_params)
    @task.status = "pending"

    if @task.save
      respond_to do |format|
        format.turbo_stream do
          render turbo_stream: [
            turbo_stream.replace("daily_total", partial: "tasks/daily_total", locals: { daily_total: calculate_daily_total }),
            turbo_stream.replace("company_monthly_totals", partial: "tasks/company_monthly_totals", locals: { totals: calculate_company_totals })
          ]
        end
        format.html { redirect_to root_path, notice: "Tarefa criada com sucesso" }
      end
    else
      @companies = Company.active.order(:name)
      render :new, status: :unprocessable_entity
    end
  end

  def edit
    @companies = Company.active.order(:name)
  end

  def update
    if @task.update(task_params)
      respond_to do |format|
        format.turbo_stream do
          render turbo_stream: [
            turbo_stream.replace("daily_total", partial: "tasks/daily_total", locals: { daily_total: calculate_daily_total }),
            turbo_stream.replace("company_monthly_totals", partial: "tasks/company_monthly_totals", locals: { totals: calculate_company_totals })
          ]
        end
        format.html { redirect_to tasks_path, notice: "Tarefa atualizada com sucesso" }
      end
    else
      @companies = Company.active.order(:name)
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @task.destroy

    respond_to do |format|
      format.turbo_stream do
        render turbo_stream: [
          turbo_stream.replace("daily_total", partial: "tasks/daily_total", locals: { daily_total: calculate_daily_total }),
          turbo_stream.replace("company_monthly_totals", partial: "tasks/company_monthly_totals", locals: { totals: calculate_company_totals })
        ]
      end
      format.html { redirect_to tasks_path, notice: "Tarefa removida com sucesso" }
    end
  end

  private

  def set_task
    @task = Task.find(params[:id])
  end

  def calculate_daily_total(filtered_tasks = nil)
    base_ids = if filtered_tasks
      filtered_tasks.unscope(:includes).where(start_date: Date.current).select(:id)
    else
      Task.where(start_date: Date.current).select(:id)
    end
    TaskItem.joins(:task).where(tasks: { id: base_ids }).sum(:hours_worked)
  end

  def calculate_company_totals(filtered_tasks = nil)
    base_relation = filtered_tasks || Task.where(start_date: Date.current.all_month)
    base_ids = base_relation.unscope(:includes).select(:id)
    Company
      .joins(tasks: :task_items)
      .where(tasks: { id: base_ids })
      .group("companies.id", "companies.name", "companies.hourly_rate")
      .select(
        "companies.id",
        "companies.name",
        "companies.hourly_rate",
        "SUM(task_items.hours_worked) as total_hours"
      )
      .order("companies.name")
  end

  def task_params
    params.require(:task).permit(:name, :company_id, :project_id, :start_date, :estimated_hours_hm, :notes)
  end
end
