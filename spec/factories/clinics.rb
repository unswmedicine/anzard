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

# Read about factories at http://github.com/thoughtbot/factory_girl

FactoryGirl.define do
  factory :clinic do
      sequence(:state) do |n| #Pick a random, real state
        states = %w(ACT NSW NT QLD SA TAS VIC WA NZ)
        states[n % states.length]
      end
      sequence(:unit_code, 100) { |n| n }
      unit_name { "Some Unit Name #{unit_code}" }
      sequence(:site_code, 100) { |n| n }
      site_name { "Some Site Name #{site_code}" }
      active true
      association :capturesystem
      after(:create) do |capturesystem|
        StaticModelPreloader.load
      end
    end
end