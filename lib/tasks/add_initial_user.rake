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

begin
  namespace :db do

    desc "Adds an initial user to a deployed instance"
    task :add_initial_user => :environment do

      #### EDIT BELOW THIS LINE
      customised = false # Set this to true
      user_attrs = {
          :email => "user@host",
          :first_name => "First",
          :last_name => "Last",
          :password => 'change me' # Use a temporary password, and change this when you first log in.
      }
      #### EDIT ABOVE THIS LINE

      raise 'Cannot add an initial user, there are already users in the database' unless User.count.eql? 0
      raise 'Cannot add an initial user, there are no roles specified. Please seed first' if Role.count.eql? 0
      raise 'Add Initial User task has not been customised. Cannot continue!' unless customised
      raise 'Initial User Password has not been changed' if user_attrs[:password].eql? 'change me'

      user = User.new(user_attrs)
      role = Role.find_by_name("Administrator")
      user.role = role
      user.activate
      user.save!

    end

  end
rescue LoadError
  puts "It looks like some Gems are missing: please run bundle install"
end
