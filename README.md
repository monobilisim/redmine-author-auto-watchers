# Redmine Author Auto Watchers

Automatically adds configured users as watchers to new issues created by a given author
(web, REST API or incoming email).

Typical use: a customer asks that a colleague can follow all issues they open. Combined with
[redmine_extended_watchers](https://github.com/maxrossello/redmine_extended_watchers) in
`protected` mode, the watcher can then see those issues even if their role only allows
"Issues created by or assigned to the user".

## Configuration

Administration → Plugins → Redmine Author Auto Watchers → Configure.

One rule per line, users identified by login or email address:

```
# author: watcher1, watcher2
alice@example.com: bob@example.com
```

The settings page lists the resolved rules and flags unknown authors.

## Behaviour

- Runs when an issue is created, before the "issue added" notification is sent, so added
  watchers receive it.
- A watcher is only added if they are active and have the "View issues" permission in the
  issue's project. Locked users and non-members are skipped silently.
- Existing issues are not changed.
- Errors are logged (`AuthorAutoWatchers:`) and never block issue creation.

## Installation

The plugin directory must be named `redmine_author_auto_watchers` (with underscores),
otherwise Redmine fails to start with `Redmine::PluginNotFound`:

```
cd /opt/redmine/plugins
git clone https://github.com/monobilisim/redmine-author-auto-watchers.git redmine_author_auto_watchers
systemctl restart puma
```

No database migration is needed. Requires Redmine 6.0 or later.

## Tests

```
bin/rails test plugins/redmine_author_auto_watchers/test
```
