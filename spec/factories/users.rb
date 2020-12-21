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

FactoryBot.define do
  factory :basic_user, class: :user do
    first_name { "Fred" }
    last_name { "Bloggs" }
    password { "Pas$w0rd" }
    sequence(:email) { |n| "#{n}@intersect.org.au" }

    allocated_unit_code { nil }

    factory :user do
      transient do
        clinics_count { 0 }
      end

      after(:create) do |user, evaluator|
        create_list(:clinic, evaluator.clinics_count, users: [user])
      end
    end

    factory :super_user do
      role { |r| Role.superuser_roles.first || r.association(:role, name: Role::SUPER_USER) }
    end
  end

end