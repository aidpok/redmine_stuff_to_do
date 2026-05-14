module StuffToDoHelper
  def stuff_to_do_issue_row(issue)
    link_to_issue(issue, subject: false, tracker: false) +
      content_tag(:span, issue.subject, class: 'stuff-to-do-subject')
  end

  def stuff_to_do_issue_meta(issue)
    [
      issue.project&.name,
      issue.status&.name,
      issue.priority&.name,
      issue.updated_on ? "Updated #{format_date(issue.updated_on)}" : nil
    ].compact.join(' / ')
  end
end
