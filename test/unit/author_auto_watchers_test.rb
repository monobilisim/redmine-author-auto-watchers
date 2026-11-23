# frozen_string_literal: true

require File.expand_path('../../../../test/test_helper', __dir__)

class AuthorAutoWatchersTest < ActiveSupport::TestCase
  include Redmine::I18n

  fixtures :projects, :users, :email_addresses, :user_preferences, :members, :member_roles, :roles,
           :trackers, :projects_trackers, :enabled_modules, :issue_statuses, :issues,
           :enumerations, :watchers

  # jsmith (2) and dlopper (3) are members of project 1, rhill (7) is not
  def setup
    User.current = nil
    ActionMailer::Base.deliveries.clear
  end

  def create_issue(author, notify: false)
    Issue.generate!(project_id: 1, tracker_id: 1, author: author, subject: 'Auto watcher test', notify: notify)
  end

  def test_parse_ignores_comments_blank_and_invalid_lines
    rules = RedmineAuthorAutoWatchers::Rules.parse("# comment\n\nJSmith: dlopper, RHill@somenet.foo;x\nnocolon\n: lonely\n")
    assert_equal [['jsmith', ['dlopper', 'rhill@somenet.foo', 'x']]], rules
  end

  def test_configured_watcher_is_added_to_new_issue_by_author_login
    with_settings plugin_redmine_author_auto_watchers: {'rules' => 'jsmith: dlopper'} do
      issue = create_issue(User.find(2))
      assert_include 3, issue.reload.watcher_user_ids
    end
  end

  def test_author_and_watcher_can_be_identified_by_email
    with_settings plugin_redmine_author_auto_watchers: {'rules' => 'JSmith@somenet.foo: dlopper@somenet.foo'} do
      issue = create_issue(User.find(2))
      assert_include 3, issue.reload.watcher_user_ids
    end
  end

  def test_watcher_is_not_added_for_other_authors
    with_settings plugin_redmine_author_auto_watchers: {'rules' => 'jsmith: dlopper'} do
      issue = create_issue(User.find(1))
      assert_not_include 3, issue.reload.watcher_user_ids
    end
  end

  def test_watcher_without_view_issues_permission_is_not_added
    with_settings plugin_redmine_author_auto_watchers: {'rules' => 'jsmith: rhill'} do
      issue = create_issue(User.find(2))
      assert_not_include 7, issue.reload.watcher_user_ids
    end
  end

  def test_locked_watcher_is_not_added
    User.find(3).lock!
    with_settings plugin_redmine_author_auto_watchers: {'rules' => 'jsmith: dlopper'} do
      issue = create_issue(User.find(2))
      assert_not_include 3, issue.reload.watcher_user_ids
    end
  end

  def test_added_watcher_receives_new_issue_notification
    User.find(3).update!(mail_notification: 'none')
    with_settings plugin_redmine_author_auto_watchers: {'rules' => 'jsmith: dlopper'},
                  notified_events: %w(issue_added) do
      create_issue(User.find(2), notify: true)
      recipients = ActionMailer::Base.deliveries.flat_map(&:bcc).compact +
                   ActionMailer::Base.deliveries.flat_map(&:to).compact +
                   ActionMailer::Base.deliveries.flat_map(&:cc).compact
      assert_include 'dlopper@somenet.foo', recipients
    end
  end

  def test_no_rules_adds_no_watchers
    with_settings plugin_redmine_author_auto_watchers: {'rules' => ''} do
      issue = create_issue(User.find(2))
      assert_not_include 3, issue.reload.watcher_user_ids
    end
  end
end
