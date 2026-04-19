#!/bin/sh
set -e

echo "==> Running DB migrations…"
bundle exec rails db:create db:migrate

echo "==> Seeding database (skipped if already populated)…"
bundle exec rails runner "
  if Employee.count.zero?
    puts 'Seeding 10,000 employees…'
    Rails.application.load_seed
  else
    puts \"Database already has #{Employee.count} employees – skipping seed.\"
  end
"

echo "==> Starting Rails server…"
exec "$@"
