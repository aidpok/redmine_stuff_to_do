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

  def stuff_to_do_issue_progress(issue)
    details = [progress_bar(issue.done_ratio, width: '120px')]
    details << l_hours(issue.estimated_hours) if issue.estimated_hours.to_f.positive?

    content_tag(:span, safe_join(details, ' '.html_safe), class: 'stuff-to-do-progress')
  end

  def stuff_to_do_pane_summary(issues)
    issues = Array(issues).compact
    return if issues.empty?

    estimate = issues.sum { |issue| issue.estimated_hours.to_f }
    details = [content_tag(:span, '', class: 'stuff-to-do-progress-key'), content_tag(:span, 'Progress')]
    details << content_tag(:span, "Estimate #{l_hours(estimate)}") if estimate.positive?

    content_tag(:div, safe_join(details), class: 'stuff-to-do-pane-summary')
  end
end
