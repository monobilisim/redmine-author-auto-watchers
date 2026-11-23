# frozen_string_literal: true

require_relative 'lib/redmine_author_auto_watchers/rules'
require_relative 'lib/redmine_author_auto_watchers/issue_patch'

Redmine::Plugin.register :redmine_author_auto_watchers do
  name 'Redmine Author Auto Watchers'
  author 'Mono'
  description 'Automatically adds configured users as watchers to issues created by a given author.'
  version '0.1.0'
  requires_redmine version_or_higher: '6.0.0'

  settings default: {'rules' => ''}, partial: 'settings/author_auto_watchers'
end

# Redmine 6+ already runs plugin init.rb files inside a to_prepare block,
# so the patch is applied directly here.
unless Issue.included_modules.include?(RedmineAuthorAutoWatchers::IssuePatch)
  Issue.include(RedmineAuthorAutoWatchers::IssuePatch)
end
