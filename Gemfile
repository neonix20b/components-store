source "https://rubygems.org"

ruby File.read('.ruby-version').strip.to_s

# Bundle edge Rails instead: gem "rails", github: "rails/rails", branch: "main"
gem "rails", "~> 7.1.3", ">= 7.1.3.2"

# The original asset pipeline for Rails [https://github.com/rails/sprockets-rails]
gem "sprockets-rails"

# Use pg as the database for Active Record
gem "pg", "~> 1.1"

# Use the Puma web server [https://github.com/puma/puma]
gem "puma", ">= 5.0"

# Use JavaScript with ESM import maps [https://github.com/rails/importmap-rails]
gem "importmap-rails"

# Hotwire's SPA-like page accelerator [https://turbo.hotwired.dev]
gem "turbo-rails"

# Hotwire's modest JavaScript framework [https://stimulus.hotwired.dev]
gem "stimulus-rails"

# Build JSON APIs with ease [https://github.com/rails/jbuilder]
gem "jbuilder"

# Use Redis adapter to run Action Cable in production
gem "redis", ">= 4.0.1", group: :production

# Use Kredis to get higher-level data types in Redis [https://github.com/rails/kredis]
# gem "kredis"

# Use Active Model has_secure_password [https://guides.rubyonrails.org/active_model_basics.html#securepassword]
# gem "bcrypt", "~> 3.1.7"

# Windows does not include zoneinfo files, so bundle the tzinfo-data gem
gem "tzinfo-data", platforms: %i[ windows jruby ]

# Reduces boot times through caching; required in config/boot.rb
gem "bootsnap", require: false

# Use Active Storage variants [https://guides.rubyonrails.org/active_storage_overview.html#transforming-images]
gem "image_processing", "~> 1.2"
gem "mini_magick"

group :development, :test do
  # See https://guides.rubyonrails.org/debugging_rails_applications.html#debugging-with-the-debug-gem
  gem "debug", platforms: %i[ mri windows ]
end

group :development do
  # Use console on exceptions pages [https://github.com/rails/web-console]
  gem "web-console"

  # Add speed badges [https://github.com/MiniProfiler/rack-mini-profiler]
  # gem "rack-mini-profiler"

  # Speed up commands on slow machines / big apps [https://github.com/rails/spring]
  # gem "spring"
  gem 'smarter_csv'
  # gem 'kramdown'
  gem 'langchainrb'
  gem "ruby-openai"
  gem 'redcarpet'
  gem 'parallel'
  gem 'hashie'
end

group :test do
  # Use system testing [https://guides.rubyonrails.org/testing.html#system-testing]
  gem "capybara"
  gem "selenium-webdriver"
end

# Use Solid Queue for background jobs
gem "solid_queue"
gem "mission_control-jobs"

# Use Solid Cache for caching
gem "solid_cache"

# Spree gems
spree_opts = { github: "spree/spree", branch: "main"}
gem "spree", spree_opts
gem "spree_emails", spree_opts
gem "spree_sample",  spree_opts
gem "spree_backend", { github: "spree/spree_backend", branch: "main" }
gem "spree_frontend", { github: "spree/spree_rails_frontend", branch: "main" }
gem "spree_auth_devise"
#gem "deface", { github: "spree/deface", branch: "master" }
gem 'spree_sitemap', github: 'spree-contrib/spree_sitemap'
gem "spree_gateway"
gem "spree_i18n"

# only needed for MacOS and Ruby 3.0
gem 'sassc', github: 'sass/sassc-ruby', branch: 'master'
gem "aws-sdk-s3", require: false
gem 'csv'
gem 'rack-host-redirect'
gem 'httparty'
gem 'mailgun-ruby'
