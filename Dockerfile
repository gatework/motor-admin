FROM --platform=$BUILDPLATFORM ruby:4.0.5-alpine AS shakapacker

ENV RAILS_ENV=production
ENV NODE_ENV=production

WORKDIR /opt

RUN apk add --no-cache nodejs yarn git build-base python3 yaml-dev && \
    gem install shakapacker

COPY ./package.json ./yarn.lock ./

RUN yarn install --network-timeout 1000000

COPY ./bin/shakapacker ./bin/shakapacker
COPY ./config/webpack ./config/webpack
COPY ./config/shakapacker.yml ./config/shakapacker.yml
COPY ./postcss.config.js ./babel.config.js ./
COPY ./app/javascript ./app/javascript

RUN printf "%s\n" "source 'https://rubygems.org'" "gem 'shakapacker', '~> 10.1'" > Gemfile && \
    bundle install && \
    ./bin/shakapacker

FROM --platform=$BUILDPLATFORM ruby:4.0.5-alpine AS assets

WORKDIR /opt/vendor/motor-admin-pro/ui

RUN apk add --no-cache nodejs yarn git build-base python3

COPY ./vendor/motor-admin-pro/ui/package.json ./vendor/motor-admin-pro/ui/yarn.lock ./

RUN yarn install --network-timeout 1000000

COPY ./vendor/motor-admin-pro/ui ./

RUN yarn build:prod

FROM ruby:4.0.5-alpine AS app

ENV RAILS_ENV=production
ENV BUNDLE_WITHOUT="development:test"

WORKDIR /opt/motor-admin

RUN apk add --no-cache freetds-dev sqlite-dev libpq-dev mariadb-dev vips build-base yaml-dev

COPY ./Gemfile ./Gemfile.lock ./
COPY ./vendor/motor-admin-pro/lib/motor/version.rb ./vendor/motor-admin-pro/lib/motor/version.rb
COPY ./vendor/motor-admin-pro/motor-admin-pro.gemspec ./vendor/motor-admin-pro/motor-admin-pro.gemspec

RUN bundle install && rm -rf ~/.bundle

COPY . ./

COPY --from=assets /opt/vendor/motor-admin-pro/ui/dist ./vendor/motor-admin-pro/ui/dist
COPY --from=shakapacker /opt/public/packs ./public/packs

RUN bundle exec bootsnap precompile --gemfile app/ lib/

RUN ln -s /opt/motor-admin/bin/motor-admin /usr/local/bin && chmod +x /usr/local/bin/motor-admin

WORKDIR /app
ENV WORKDIR=/app/

CMD ["motor-admin"]
