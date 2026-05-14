# Redmine Stuff To Do

Per-user ordered work queues for Redmine issues.

This plugin adds a **Stuff To Do** view where users can order their own assigned work, while administrators can manage another user's queue. The first five queued issues are treated as the user's current focus, and the rest are shown as recommended next work.

## Features

- Per-user ordered issue queues
- "Doing now" and "recommended next" sections
- Administrator view for managing another user's queue
- Available assigned issues with text, project, status, and priority filters
- Drag available issues into a queue
- Reorder queued issues with an explicit save step
- Bulk add the first five matching available issues
- Automatically removes closed, deleted, or reassigned issues from queues
- Application and project menu entries before Redmine's Issues tab

## Compatibility

- Redmine 6.0 or newer
- Tested during development against Redmine 6.1

## Installation

From your Redmine root:

```bash
cd /path/to/redmine
git clone <repo-url> plugins/redmine_stuff_to_do
bundle exec rails redmine:plugins:migrate RAILS_ENV=production
```

Then restart Redmine.

For Docker-based Redmine installs, mount the plugin directory as persistent host storage. For example:

```yaml
services:
  redmine:
    volumes:
      - ./plugins:/usr/src/redmine/plugins
```

The plugin should live at:

```text
plugins/redmine_stuff_to_do
```

## Upgrading

```bash
cd /path/to/redmine/plugins/redmine_stuff_to_do
git pull
cd /path/to/redmine
bundle exec rails redmine:plugins:migrate RAILS_ENV=production
```

Then restart Redmine.

## Uninstalling

From your Redmine root:

```bash
bundle exec rails redmine:plugins:migrate NAME=redmine_stuff_to_do VERSION=0 RAILS_ENV=production
rm -rf plugins/redmine_stuff_to_do
```

Then restart Redmine.

## Data Model

The plugin creates one table:

- `stuff_to_dos`

Each row links a Redmine user to an issue and stores its queue position.

This plugin does not implement the legacy Time Grid feature and does not create or modify a `time_grid_issues_users` table. If you are migrating from an older Stuff To Do-style plugin and already have that table, this plugin leaves it untouched.

## Legacy Inspiration

This project was inspired by the original Redmine Stuff To Do plugin by Eric Davis:

- https://github.com/edavis10/redmine-stuff-to-do-plugin
- https://www.redmine.org/plugins/stuff-to-do-plugin

This implementation targets modern Redmine versions and was rewritten as a small Redmine 6 plugin.

## License

GPL-2.0-or-later. See [LICENSE](LICENSE).
