class StuffToDo < ActiveRecord::Base
  self.table_name = 'stuff_to_dos'

  belongs_to :user
  belongs_to :stuff, polymorphic: true

  scope :for_user, ->(user) { where(user_id: user.id) }
  scope :ordered, -> { order(:position, :id) }
  scope :issues, -> { where(stuff_type: 'Issue') }
  scope :open_issues, lambda {
    issues.
      joins('INNER JOIN issues ON issues.id = stuff_to_dos.stuff_id').
      joins('INNER JOIN issue_statuses ON issue_statuses.id = issues.status_id').
      where(issue_statuses: {is_closed: false})
  }

  def self.doing_now(user)
    active_queue_for(user).limit(5)
  end

  def self.recommended(user)
    active_queue_for(user).offset(5)
  end

  def self.issue_ids_for(user)
    for_user(user).issues.pluck(:stuff_id)
  end

  def self.available_issues_for(user, viewer, filters = {})
    scope = available_issue_scope_for(user, viewer)
    scope = filter_available_issues(scope, filters)
    scope.includes(:project, :status, :priority, :assigned_to).order(created_on: :desc)
  end

  def self.available_issue_scope_for(user, viewer)
    excluded_ids = issue_ids_for(user)
    scope = Issue.visible(viewer).open.where(assigned_to_id: user.id)
    scope = scope.where.not(id: excluded_ids) if excluded_ids.any?
    scope
  end

  def self.add_issue!(user, issue)
    transaction do
      item = for_user(user).issues.find_or_initialize_by(stuff_id: issue.id)
      if item.new_record?
        item.position = next_position_for(user)
        item.save!
      end
      renumber!(user)
      item
    end
  end

  def self.remove_item!(user, item_id)
    transaction do
      item = for_user(user).find(item_id)
      item.destroy!
      renumber!(user)
    end
  end

  def self.remove_associations_to(stuff)
    user_ids = where(stuff: stuff).pluck(:user_id)
    where(stuff: stuff).delete_all
    renumber_users(user_ids)
  end

  def self.remove_stale_assignments(issue)
    if issue.assigned_to_id.present?
      stale = where(stuff: issue).where.not(user_id: issue.assigned_to_id)
    else
      stale = where(stuff: issue)
    end
    user_ids = stale.pluck(:user_id)
    stale.delete_all
    renumber_users(user_ids)
  end

  def self.reorder!(user, items, viewer)
    values = Array(items).map(&:to_s).reject(&:blank?)
    transaction do
      existing_items = for_user(user).issues.index_by(&:id)
      available_issues = Issue.visible(viewer).open.where(assigned_to_id: user.id)
      ordered_item_ids = []

      values.each_with_index do |value, index|
        item = item_from_queue_value(user, value, existing_items, available_issues)
        next unless item

        item.update_columns(position: index + 1)
        ordered_item_ids << item.id
      end
      for_user(user).issues.where.not(id: ordered_item_ids).delete_all
      renumber!(user)
    end
  end

  def self.renumber!(user)
    for_user(user).ordered.each_with_index do |item, index|
      item.update_columns(position: index + 1) unless item.position == index + 1
    end
  end

  def self.next_position_for(user)
    (for_user(user).maximum(:position) || 0) + 1
  end

  def self.active_queue_for(user)
    for_user(user).open_issues.ordered
  end

  def self.renumber_users(user_ids)
    User.where(id: user_ids.compact.uniq).find_each { |user| renumber!(user) }
  end

  def self.item_from_queue_value(user, value, existing_items, available_issues)
    type, id = value.split(':', 2)
    id = id.to_i

    if type == 'item'
      existing_items[id]
    elsif type == 'issue'
      issue = available_issues.find_by(id: id)
      add_issue!(user, issue) if issue
    end
  end

  def self.filter_available_issues(scope, filters)
    query = filters[:q].to_s.strip
    scope = scope.where(project_id: filters[:project_id]) if filters[:project_id].present?
    scope = scope.where(status_id: filters[:status_id]) if filters[:status_id].present?
    scope = scope.where(priority_id: filters[:priority_id]) if filters[:priority_id].present?
    return scope if query.blank?

    pattern = "%#{sanitize_sql_like(query.downcase)}%"
    scope.where('LOWER(issues.subject) LIKE ? OR CAST(issues.id AS CHAR) LIKE ?', pattern, pattern)
  end
end
