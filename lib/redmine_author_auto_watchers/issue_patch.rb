# frozen_string_literal: true

module RedmineAuthorAutoWatchers
  module IssuePatch
    def self.included(base)
      # after_commit callbacks run in reverse order of definition, so this one,
      # defined after Issue#send_notification, runs before the "new issue"
      # notification is sent and the added watchers receive it.
      base.after_create_commit :add_author_auto_watchers
    end

    private

    def add_author_auto_watchers
      RedmineAuthorAutoWatchers::Rules.watchers_for(author).each do |user|
        # Only users who can view issues in the project (required for the
        # redmine_extended_watchers "protected" policy to grant visibility)
        next unless user.allowed_to?(:view_issues, project)
        next if watcher_user_ids.include?(user.id)

        add_watcher(user)
      end
    rescue StandardError => e
      Rails.logger.error "AuthorAutoWatchers: could not add watchers to issue ##{id}: #{e.class}: #{e.message}"
    end
  end
end
