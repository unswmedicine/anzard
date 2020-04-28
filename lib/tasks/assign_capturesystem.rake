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
    desc "Assign a capture system to a user"
    task :assign_capturesystem, [:capturesystem_name, :user_email] => :environment do |task, args|
      if !args[:capturesystem_name].nil? && !args[:user_email].nil? 
        the_user=User.find_by(email: args[:user_email])
        the_capturesystem=Capturesystem.find_by(name:args[:capturesystem_name])
        if the_user.nil? || the_capturesystem.nil?
          puts 'Could not find the user or capture system'
        else
          begin
            CapturesystemUser.create!(user_id: the_user.id, capturesystem_id: the_capturesystem.id)
            puts "capturesystem [#{args[:capturesystem_name]}] has been assigned to user [#{args[:user_email]}]"
          rescue ActiveRecord::RecordInvalid => e
            puts e.inspect
          end
        end
      else
        puts 'Invalid parameters !'
      end
    end
  end

rescue LoadError
  puts "It looks like some Gems are missing: please run bundle install"  
end