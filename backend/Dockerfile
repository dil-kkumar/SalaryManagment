FROM ruby:3.2.2 AS base

# Runtime dependencies
RUN apt-get update && apt-get install -y --no-install-recommends \
    build-essential \
    sqlite3 \
    libsqlite3-dev \
    tzdata \
    curl \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /app

# ── Gem install layer (cached unless Gemfile changes) ──────────────────────
COPY Gemfile ./
# Generate fresh Gemfile.lock inside the image
RUN bundle install --jobs 4 --retry 3

# ── Application code ───────────────────────────────────────────────────────
COPY . .

# Ensure DB directory exists and is writable
RUN mkdir -p db

COPY entrypoint.sh /usr/local/bin/entrypoint.sh
RUN chmod +x /usr/local/bin/entrypoint.sh

EXPOSE 3001

ENTRYPOINT ["entrypoint.sh"]
CMD ["bundle", "exec", "rackup", "config.ru", "-o", "0.0.0.0", "-p", "3001"]
