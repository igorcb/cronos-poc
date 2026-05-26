class TasksController < ApplicationController
  include DashboardCalculations

  before_action :require_authentication
  before_action :set_task, only: [ :edit, :update, :destroy, :deliver, :reopen, :reopen_modal ]

  def index
    @tasks = scoped_tasks
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

    @companies = scoped_companies.active.order(:name)
    # Multi-tenant (story 9.2 QA #9): evitar merge(Company.active) — confuso semanticamente.
    # Usar where(companies: { active: true }) explicito mantém escopo do tenant claro.
    @projects = company_id ?
      scoped_projects.where(company_id: company_id).order(:name) :
      scoped_projects.joins(:company).where(companies: { active: true }).order(:name)
  end

  def new
    @task = scoped_tasks.new
    @companies = scoped_companies.active.order(:name)
  end

  def create
    @task = scoped_tasks.new(task_params)
    @task.status = "pending" unless @task.status.in?(Task.statuses.keys)
    # Story 9.3 — DM-008 (QA #H1): captura antes do save vale para AMBOS
    # os branches (HTML e Turbo-Frame=modal). Sem esse cuidado, primeira
    # task criada via modal do dashboard nunca mostrava o flash de conclusão.
    first_task_of_onboarding = !Current.user.tasks.exists?

    if @task.save
      task_create_notice = first_task_of_onboarding ?
                             t("onboarding.flashes.completed") :
                             "Tarefa criada com sucesso"

      if request.headers["Turbo-Frame"] == "modal"
        flash.now[:notice] = task_create_notice
        avg_per_delivery = calculate_monthly_avg_per_delivery
        render turbo_stream: [
          turbo_stream.update("modal", ""),
          turbo_stream.update("flash", partial: "shared/flash"),
          turbo_stream.prepend("tasks-list", partial: "dashboard/task_row", locals: { task: @task }),
          turbo_stream.replace("dashboard_daily_hours",        partial: "dashboard/daily_hours",        locals: { daily_hours: calculate_daily_hours }),
          turbo_stream.replace("dashboard_monthly_hours",      partial: "dashboard/monthly_hours",      locals: { monthly_hours: calculate_monthly_hours }),
          turbo_stream.replace("dashboard_monthly_value",      partial: "dashboard/monthly_value",      locals: { monthly_value: calculate_monthly_value }),
          turbo_stream.replace("dashboard_daily_task_count",   partial: "dashboard/daily_task_count",   locals: { daily_task_count: calculate_daily_task_count }),
          turbo_stream.replace("dashboard_monthly_task_count", partial: "dashboard/monthly_task_count", locals: { monthly_task_count: calculate_monthly_task_count }),
          turbo_stream.replace("dashboard_daily_value",        partial: "dashboard/daily_value",        locals: { daily_value: calculate_daily_value }),
          turbo_stream.replace("kpi-entregas-mes",             partial: "dashboard/delivered_count",    locals: { monthly_delivered_count: calculate_monthly_delivered_count }),
          turbo_stream.replace("kpi-horas-entregues",          partial: "dashboard/delivered_hours",    locals: { monthly_delivered_hours: calculate_monthly_delivered_hours }),
          turbo_stream.replace("kpi-valor-entregue",           partial: "dashboard/delivered_value",    locals: { monthly_delivered_value: calculate_monthly_delivered_value }),
          turbo_stream.replace("kpi-media-por-entrega",        partial: "dashboard/avg_per_delivery",        locals: { avg_per_delivery: avg_per_delivery }),
          turbo_stream.replace("kpi-media-por-entrega-inline", partial: "dashboard/avg_per_delivery_inline", locals: { avg_per_delivery: avg_per_delivery })
        ]
      else
        redirect_to tasks_path, notice: task_create_notice
      end
    else
      @companies = scoped_companies.active.order(:name)
      render :new, status: :unprocessable_entity
    end
  end

  def edit
    set_edit_form_collections
  end

  def update
    permitted = task_params
    permitted.delete(:status) if @task.delivered?
    if @task.update(permitted)
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
      set_edit_form_collections
      render :edit, status: :unprocessable_entity
    end
  end

  def deliver
    if @task.update(status: "delivered")
      respond_to do |format|
        format.turbo_stream do
          avg_per_delivery = calculate_monthly_avg_per_delivery
          render turbo_stream: [
            turbo_stream.replace("task_row_#{@task.id}", partial: "dashboard/task_row", locals: { task: @task }),
            turbo_stream.replace("dashboard_daily_task_count",   partial: "dashboard/daily_task_count",   locals: { daily_task_count: calculate_daily_task_count }),
            turbo_stream.replace("dashboard_monthly_task_count", partial: "dashboard/monthly_task_count", locals: { monthly_task_count: calculate_monthly_task_count }),
            turbo_stream.update("tasks-list", partial: "dashboard/tasks_list", locals: { tasks: monthly_tasks }),
            turbo_stream.replace("kpi-entregas-mes",             partial: "dashboard/delivered_count",         locals: { monthly_delivered_count: calculate_monthly_delivered_count }),
            turbo_stream.replace("kpi-horas-entregues",          partial: "dashboard/delivered_hours",         locals: { monthly_delivered_hours: calculate_monthly_delivered_hours }),
            turbo_stream.replace("kpi-valor-entregue",           partial: "dashboard/delivered_value",         locals: { monthly_delivered_value: calculate_monthly_delivered_value }),
            turbo_stream.replace("kpi-media-por-entrega",        partial: "dashboard/avg_per_delivery",        locals: { avg_per_delivery: avg_per_delivery }),
            turbo_stream.replace("kpi-media-por-entrega-inline", partial: "dashboard/avg_per_delivery_inline", locals: { avg_per_delivery: avg_per_delivery })
          ]
        end
        format.html { redirect_to tasks_path, notice: "Tarefa entregue com sucesso" }
      end
    else
      respond_to do |format|
        format.turbo_stream { head :unprocessable_entity }
        format.html { redirect_to tasks_path, alert: "Não foi possível entregar a tarefa" }
      end
    end
  end

  def reopen_modal
    render partial: "reopen_confirmation_modal", locals: { task: @task }
  end

  def reopen
    unless @task.delivered?
      respond_to do |format|
        format.turbo_stream { head :unprocessable_content }
        format.html { redirect_to edit_task_path(@task), alert: "Apenas tarefas entregues podem ser reabertas." }
      end
      return
    end

    @task.update!(
      status: :completed,
      delivery_date: nil,
      delivered_value: nil,
      hourly_rate: nil
    )

    respond_to do |format|
      format.turbo_stream do
        avg_per_delivery = calculate_monthly_avg_per_delivery
        render turbo_stream: [
          turbo_stream.replace("task_row_#{@task.id}", partial: "dashboard/task_row", locals: { task: @task }),
          turbo_stream.replace("dashboard_daily_task_count",   partial: "dashboard/daily_task_count",   locals: { daily_task_count: calculate_daily_task_count }),
          turbo_stream.replace("dashboard_monthly_task_count", partial: "dashboard/monthly_task_count", locals: { monthly_task_count: calculate_monthly_task_count }),
          turbo_stream.update("tasks-list", partial: "dashboard/tasks_list", locals: { tasks: monthly_tasks }),
          turbo_stream.replace("kpi-entregas-mes",             partial: "dashboard/delivered_count",         locals: { monthly_delivered_count: calculate_monthly_delivered_count }),
          turbo_stream.replace("kpi-horas-entregues",          partial: "dashboard/delivered_hours",         locals: { monthly_delivered_hours: calculate_monthly_delivered_hours }),
          turbo_stream.replace("kpi-valor-entregue",           partial: "dashboard/delivered_value",         locals: { monthly_delivered_value: calculate_monthly_delivered_value }),
          turbo_stream.replace("kpi-media-por-entrega",        partial: "dashboard/avg_per_delivery",        locals: { avg_per_delivery: avg_per_delivery }),
          turbo_stream.replace("kpi-media-por-entrega-inline", partial: "dashboard/avg_per_delivery_inline", locals: { avg_per_delivery: avg_per_delivery })
        ]
      end
      format.html { redirect_to edit_task_path(@task), notice: "Tarefa reaberta com sucesso. Você pode editar os dados agora." }
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
    @task = scoped_tasks.find(params[:id])
  end

  def set_edit_form_collections
    @companies = scoped_companies.active.order(:name)
    @projects = @task.company&.projects&.order(:name) || []
  end

  def calculate_daily_total(filtered_tasks = nil)
    base = filtered_tasks || scoped_tasks
    task_ids = base.unscope(:includes).select(:id)
    TaskItem.total_minutes(scoped_task_items.where(work_date: Date.current, task_id: task_ids))
  end

  def calculate_company_totals(filtered_tasks = nil)
    base_relation = filtered_tasks || scoped_tasks.where(start_date: Date.current.all_month)
    base_ids = base_relation.unscope(:includes).select(:id)
    scoped_companies
      .joins(tasks: :task_items)
      .where(tasks: { id: base_ids })
      .group("companies.id", "companies.name", "companies.hourly_rate")
      .select(
        "companies.id",
        "companies.name",
        "companies.hourly_rate",
        "FLOOR(SUM(#{TaskItem::DURATION_SECONDS_SQL_PREFIXED}) / 60) as total_minutes",
        "SUM(#{TaskItem::DURATION_SECONDS_SQL_PREFIXED}) / 3600.0 as total_hours"
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

  def task_params
    params.require(:task).permit(:code, :name, :company_id, :project_id, :start_date, :end_date, :estimated_hours_hm, :notes, :status)
  end
end
