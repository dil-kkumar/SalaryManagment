FROM ruby:3.2.2-alpine AS base

# Runtime dependencies
RUN apk add --no-cache \
      build-base \
      sqlite-dev \
      sqlite \
      tzdata \
      curl

WORKDIR /app

# ── Gem install layer (cached unless Gemfile changes) ──────────────────────
COPY Gemfile ./
# Generate fresh Gemfile.lock inside the image
RUN bundle config set --local without 'development test' && \
    bundle install --jobs 4 --retry 3

# ── Application code ───────────────────────────────────────────────────────
COPY . .

# Ensure DB directory exists and is writable
RUN mkdir -p db

COPY entrypoint.sh /usr/local/bin/entrypoint.sh
RUN chmod +x /usr/local/bin/entrypoint.sh

EXPOSE 3001

ENTRYPOINT ["entrypoint.sh"]
CMD ["bundle", "exec", "rails", "server", "-b", "0.0.0.0", "-p", "3001"]
