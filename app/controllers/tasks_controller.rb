class TasksController < ApplicationController
  before_action :require_authentication
  before_action :set_task, only: [ :edit, :update, :destroy ]

  def index
    @tasks = Task
      .includes(:company, :project, :task_items)
      .where(start_date: resolve_period_range)
      .order(start_date: :desc, created_at: :desc)

    company_id = params[:company_id].present? ? params[:company_id].to_i : nil
    project_id = params[:project_id].present? ? params[:project_id].to_i : nil

    @tasks = @tasks.by_company(company_id) if company_id
    @tasks = @tasks.by_project(project_id) if project_id
    @tasks = @tasks.where(status: params[:status]) if params[:status].in?(Task.statuses.keys)

    @daily_total = calculate_daily_total(@tasks)
    @company_monthly_totals = calculate_company_totals(@tasks)

    @filtered_count = @tasks.count
    @is_filtered = (company_id&.positive?) || (project_id&.positive?) ||
                   params[:status].in?(Task.statuses.keys) ||
                   (params[:period].present? && params[:period] != "current_month")
    @period_label = resolve_period_label

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
    @task.status = "pending" unless @task.status.in?(Task.statuses.keys)

    if @task.save
      if request.headers["Turbo-Frame"] == "modal"
        daily_hours        = calculate_dashboard_daily_hours
        monthly_hours      = calculate_dashboard_monthly_hours
        monthly_value      = calculate_dashboard_monthly_value
        daily_task_count   = calculate_dashboard_daily_task_count
        monthly_task_count = calculate_dashboard_monthly_task_count
        daily_value        = calculate_dashboard_daily_value
        render turbo_stream: [
          turbo_stream.update("modal", ""),
          turbo_stream.prepend("tasks-list", partial: "dashboard/task_row", locals: { task: @task }),
          turbo_stream.replace("dashboard_daily_hours",        partial: "dashboard/daily_hours",        locals: { daily_hours: daily_hours }),
          turbo_stream.replace("dashboard_monthly_hours",      partial: "dashboard/monthly_hours",      locals: { monthly_hours: monthly_hours }),
          turbo_stream.replace("dashboard_monthly_value",      partial: "dashboard/monthly_value",      locals: { monthly_value: monthly_value }),
          turbo_stream.replace("dashboard_daily_task_count",   partial: "dashboard/daily_task_count",   locals: { daily_task_count: daily_task_count }),
          turbo_stream.replace("dashboard_monthly_task_count", partial: "dashboard/monthly_task_count", locals: { monthly_task_count: monthly_task_count }),
          turbo_stream.replace("dashboard_daily_value",        partial: "dashboard/daily_value",        locals: { daily_value: daily_value })
        ]
      else
        redirect_to tasks_path, notice: "Tarefa criada com sucesso"
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
    if @task.destroy
      respond_to do |format|
        format.turbo_stream do
          render turbo_stream: [
            turbo_stream.remove(ActionView::RecordIdentifier.dom_id(@task)),
            turbo_stream.replace("daily_total", partial: "tasks/daily_total", locals: { daily_total: calculate_daily_total }),
            turbo_stream.replace("company_monthly_totals", partial: "tasks/company_monthly_totals", locals: { totals: calculate_company_totals })
          ]
        end
        format.html { redirect_to tasks_path, notice: "Tarefa removida com sucesso" }
      end
    else
      redirect_to tasks_path, alert: "Não foi possível remover a tarefa"
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
    relation = TaskItem.joins(:task).where(tasks: { id: base_ids })
    TaskItem.total_minutes(relation)
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
        "FLOOR(SUM(EXTRACT(EPOCH FROM (task_items.end_time - task_items.start_time))) / 60) as total_minutes",
        "SUM(EXTRACT(EPOCH FROM (task_items.end_time - task_items.start_time))) / 3600.0 as total_hours"
      )
      .order("companies.name")
  end

  def resolve_period_label
    case params[:period]
    when "last_month"    then "o mês anterior"
    when "last_7_days"   then "os últimos 7 dias"
    when "current_week"  then "a semana atual"
    when "custom"        then "o período selecionado"
    else "este mês"
    end
  end

  def resolve_period_range
    case params[:period]
    when "current_month"  then Date.current.all_month
    when "last_month"     then 1.month.ago.all_month
    when "last_7_days"    then 7.days.ago.to_date..Date.current
    when "current_week"   then Date.current.all_week
    when "custom"
      start_d = params[:start_date].present? ? (Date.parse(params[:start_date]) rescue nil) : nil
      end_d   = params[:end_date].present?   ? (Date.parse(params[:end_date])   rescue nil) : nil
      (start_d && end_d) ? start_d..end_d : Date.current.all_month
    else
      Date.current.all_month
    end
  end

  def calculate_dashboard_daily_hours
    TaskItem.total_minutes(TaskItem.joins(:task).where(tasks: { start_date: Date.current }))
  end

  def calculate_dashboard_monthly_hours
    TaskItem.total_minutes(TaskItem.joins(:task).where(tasks: { start_date: Date.current.all_month }))
  end

  def calculate_dashboard_monthly_value
    Company
      .joins(tasks: :task_items)
      .where(tasks: { start_date: Date.current.all_month })
      .sum("EXTRACT(EPOCH FROM (task_items.end_time - task_items.start_time)) / 3600.0 * companies.hourly_rate")
  end

  def calculate_dashboard_daily_task_count
    Task.joins(:task_items)
        .where(task_items: { work_date: Date.current })
        .distinct
        .count
  end

  def calculate_dashboard_monthly_task_count
    Task.joins(:task_items)
        .where(task_items: { work_date: Date.current.all_month })
        .distinct
        .count
  end

  def calculate_dashboard_daily_value
    TaskItem.joins(task: :company)
            .where(work_date: Date.current)
            .sum("EXTRACT(EPOCH FROM (task_items.end_time - task_items.start_time)) / 3600.0 * companies.hourly_rate")
  end

  def task_params
    params.require(:task).permit(:code, :name, :company_id, :project_id, :start_date, :estimated_hours_hm, :notes, :status)
  end
end
