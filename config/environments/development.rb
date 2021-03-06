# ANZARD - Australian & New Zealand Assisted Reproduction Database
# Copyright (C) 2017 Intersect Australia Ltd
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program. If not, see <http://www.gnu.org/licenses/>.

Anzard::Application.configure do

  config.action_mailer.default_url_options = { :host => 'localhost:3000' }

  # Settings specified here will take precedence over those in config/application.rb

  # use default file_store for now as memory_store in rails 6.0.x 6.1.x as slowed drastically(bug)
  # cache files live in app_root/tmp/cache folder, delete this folder after survey updates
  config.cache_store = :memory_store, {size: 64.megabytes}

  # In the development environment your application's code is reloaded on
  # every request.  This slows down response time but is perfect for development
  # since you don't have to restart the web server when you make code changes.
  config.cache_classes = false
  config.log_level = :debug

  # Log error messages when you accidentally call methods on nil.
  config.whiny_nils = true

  # Show full error reports and disable caching
  config.consider_all_requests_local       = true
  config.action_controller.perform_caching = false

  # Don't care if the mailer can't send
  config.action_mailer.raise_delivery_errors = false

  # Print deprecation notices to the Rails logger
  config.active_support.deprecation = :raise

  # Only use best-standards-support built into browsers
  config.action_dispatch.best_standards_support = :builtin

  # Do not compress assets
  config.assets.compress = false

  # Expands the lines which load the assets
  config.assets.debug = true

  config.eager_load = false

  #need to reset seceret_base_key if changed cookies_serializer
  config.action_dispatch.cookies_serializer = :json

  config.hosts << "npesu.med.unsw.edu.au"
  config.hosts << "anzard.med.unsw.edu.au"
  config.hosts << "varta.med.unsw.edu.au"
end
