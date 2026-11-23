# frozen_string_literal: true

module RedmineAuthorAutoWatchers
  # Parses the rules setting. One rule per line:
  #
  #   author: watcher1, watcher2
  #
  # Each user is identified by login or email address (case insensitive).
  # Blank lines and lines starting with # are ignored.
  module Rules
    module_function

    def setting_text
      settings = Setting.plugin_redmine_author_auto_watchers
      settings.is_a?(Hash) ? settings['rules'].to_s : ''
    end

    # Returns [[author_key, [watcher_key, ...]], ...] with keys downcased
    def parse(text = setting_text)
      text.to_s.each_line.filter_map do |line|
        line = line.strip
        next if line.empty? || line.start_with?('#')

        author, watchers = line.split(':', 2)
        next if watchers.nil?

        author = author.strip.downcase
        watchers = watchers.split(/[,;\s]+/).map {|w| w.strip.downcase}.reject(&:empty?)
        next if author.empty? || watchers.empty?

        [author, watchers]
      end
    end

    # Returns the active users configured as auto watchers for the given author
    def watchers_for(author, text = setting_text)
      return [] unless author.is_a?(User)

      author_keys = [author.login.to_s.downcase] + author.mails.map(&:downcase)
      keys = parse(text).select {|a, _| author_keys.include?(a)}.flat_map(&:last).uniq
      return [] if keys.empty?

      users_by_login = User.active.where('LOWER(login) IN (?)', keys).to_a
      users_by_mail = User.active.having_mail(keys).to_a
      (users_by_login + users_by_mail).uniq - [author]
    end
  end
end
