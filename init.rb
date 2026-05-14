require File.expand_path('../lib/redmine_stuff_to_do/access', __FILE__)
require File.expand_path('../lib/redmine_stuff_to_do/issue_patch', __FILE__)

Rails.configuration.to_prepare do
  Issue.include RedmineStuffToDo::IssuePatch unless Issue.included_modules.include?(RedmineStuffToDo::IssuePatch)
end

Redmine::Plugin.register :redmine_stuff_to_do do
  name 'Stuff To Do'
  author 'Redmine Stuff To Do contributors'
  description 'Per-user ordered work queues for Redmine issues'
  version '0.1.0'
  requires_redmine version_or_higher: '6.0'

  menu :application_menu, :stuff_to_do, {
    controller: 'stuff_to_do',
    action: 'index'
  }, caption: 'Stuff To Do', before: :issues, if: Proc.new { RedmineStuffToDo::Access.visible_to?(User.current) }

  menu :project_menu, :stuff_to_do, {
    controller: 'stuff_to_do',
    action: 'index'
  }, caption: 'Stuff To Do', before: :issues, param: :project_id, permission: false, if: Proc.new { RedmineStuffToDo::Access.visible_to?(User.current) }
end
