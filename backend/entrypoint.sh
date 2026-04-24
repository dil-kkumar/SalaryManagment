#!/bin/sh
set -e

cd /app

echo "==> Checking gems…"
bundle check || bundle install --jobs 4 --retry 3

echo "==> Running DB migrations…"
bundle exec rake db:create db:migrate

echo "==> Seeding database (skipped if already populated)…"
bundle exec ruby -e "
  require './config/environment'

  if Employee.count.zero?
    puts 'Seeding 10,000 employees...'
    Rails.application.load_seed
  else
    puts \"Database already has #{Employee.count} employees - skipping seed.\"
  end
"

echo "==> Starting Rails server…"
exec "$@"
