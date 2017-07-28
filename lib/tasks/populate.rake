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

require File.dirname(__FILE__) + '/sample_data_populator.rb'
begin  
  namespace :db do  
    desc "Populate the database with some sample data for testing"
    task :populate => :environment do  
      populate_data
    end
  end

  namespace :db do
    desc "Populate the database with realistic data for performance testing"
    task :perf_populate => :environment do
      populate_data(true)
    end
  end
rescue LoadError
  puts "It looks like some Gems are missing: please run bundle install"  
end