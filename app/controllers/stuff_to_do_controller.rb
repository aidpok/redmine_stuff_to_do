class StuffToDoController < ApplicationController
  before_action :require_login
  before_action :find_target_user
  before_action :require_stuff_to_do_access

  helper :stuff_to_do
  helper :issues

  accept_api_auth :index

  def index
    load_board
  end

  def add
    issue = Issue.visible(User.current).open.find(params[:issue_id])
    StuffToDo.add_issue!(@user, issue)
    redirect_to stuff_to_do_path(filter_params.merge(user_id: @user.id))
  rescue ActiveRecord::RecordNotFound
    render_404
  end

  def add_filtered
    issues = StuffToDo.available_issues_for(@user, User.current, filter_params).limit(5).to_a
    issues.each { |issue| StuffToDo.add_issue!(@user, issue) }
    flash[:notice] = "#{issues.size} issue#{'s' unless issues.size == 1} added to #{@user.name}'s Stuff To Do."
    redirect_to stuff_to_do_path(filter_params.merge(user_id: @user.id))
  rescue ActiveRecord::RecordNotFound
    render_404
  end

  def remove
    StuffToDo.remove_item!(@user, params[:id])
    redirect_to stuff_to_do_path(filter_params.merge(user_id: @user.id))
  rescue ActiveRecord::RecordNotFound
    render_404
  end

  def reorder
    StuffToDo.reorder!(@user, params[:queue_items], User.current)
    redirect_to stuff_to_do_path(filter_params.merge(user_id: @user.id))
  end

  private

  def find_target_user
    requested_id = params[:user_id].presence
    @user = if requested_id && requested_id.to_i != User.current.id
              User.active.find(requested_id)
            else
              User.current
            end
  rescue ActiveRecord::RecordNotFound
    render_404
  end

  def require_stuff_to_do_access
    render_403 unless RedmineStuffToDo::Access.can_view?(User.current, @user)
  end

  def load_board
    @users = RedmineStuffToDo::Access.selectable_users_for(User.current)
    @doing_now = StuffToDo.doing_now(@user).includes(stuff: [:project, :status, :priority, :assigned_to])
    @recommended = StuffToDo.recommended(@user).includes(stuff: [:project, :status, :priority, :assigned_to])
    @queued_items = @doing_now + @recommended
    @available_filters = filter_params
    @available_query = @available_filters[:q].to_s
    @available_total_count = StuffToDo.available_issues_for(@user, User.current).count
    @available_scope = StuffToDo.available_issues_for(@user, User.current, @available_filters)
    @available_filtered_count = @available_scope.count
    @available_page = [params[:page].to_i, 1].max
    @available_per_page = 50
    @available_total_pages = [(@available_filtered_count.to_f / @available_per_page).ceil, 1].max
    @available_page = @available_total_pages if @available_page > @available_total_pages
    @available = @available_scope.offset((@available_page - 1) * @available_per_page).limit(@available_per_page)
    @available_filter_options = available_filter_options
    @managed_user_options = managed_user_options
  end

  def managed_user_options
    @users.map do |user|
      queue_count = StuffToDo.active_queue_for(user).count
      available_count = StuffToDo.available_issues_for(user, User.current).count
      label = "#{user.name} (#{queue_count} queued, #{available_count} available)"
      [label, user.id]
    end
  end

  def available_filter_options
    base_scope = StuffToDo.available_issue_scope_for(@user, User.current)
    project_ids = base_scope.distinct.pluck(:project_id).compact
    status_ids = base_scope.distinct.pluck(:status_id).compact
    priority_ids = base_scope.distinct.pluck(:priority_id).compact

    {
      projects: Project.where(id: project_ids).order(:name),
      statuses: IssueStatus.where(id: status_ids).order(:position),
      priorities: IssuePriority.where(id: priority_ids).order(:position)
    }
  end

  def filter_params
    {
      q: params[:q].to_s.strip,
      project_id: params[:project_id].presence,
      status_id: params[:status_id].presence,
      priority_id: params[:priority_id].presence
    }.delete_if { |_key, value| value.blank? }
  end
  helper_method :filter_params

end
