module RedmineStuffToDo
  module Access
    MANAGER_ROLE_NAMES = ['Administrator'].freeze

    module_function

    def visible_to?(user)
      user.present? && user.logged? && (manager?(user) || queued_user?(user) || assigned_issue_user?(user))
    end

    def manager?(user)
      user.present? && user.logged? && (user.admin? || (role_names(user) & MANAGER_ROLE_NAMES).any?)
    end

    def can_view?(user, target_user)
      return false unless user.present? && user.logged? && target_user.present?
      user.id == target_user.id || manager?(user)
    end

    def can_manage?(user, target_user)
      can_view?(user, target_user)
    end

    def selectable_users_for(user)
      return [user] unless manager?(user)

      ids = queued_user_ids + assigned_user_ids
      users = User.active.where(id: ids).to_a
      users |= [user] if user.present? && user.logged?
      users.sort_by { |u| [u.lastname.to_s.downcase, u.firstname.to_s.downcase, u.login.to_s.downcase] }
    end

    def role_names(user)
      user.memberships.includes(:roles).flat_map { |membership| membership.roles.map(&:name) }.uniq
    end

    def queued_user?(user)
      StuffToDo.where(user_id: user.id).exists?
    rescue StandardError
      false
    end

    def assigned_issue_user?(user)
      Issue.open.where(assigned_to_id: user.id).exists?
    rescue StandardError
      false
    end

    def queued_user_ids
      StuffToDo.distinct.pluck(:user_id).compact
    rescue StandardError
      []
    end

    def assigned_user_ids
      Issue.open.where.not(assigned_to_id: nil).distinct.pluck(:assigned_to_id).compact
    rescue StandardError
      []
    end
  end
end
