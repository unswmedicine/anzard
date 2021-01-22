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

FactoryBot.define do
  factory :question do
    sequence :question_order
    question { "What?" }
    association :section
    question_type { "Text" }
    code { "What" }
    after(:create) do |survey|
      #StaticModelPreloader is deprecated, use the builtin association mechanism
      #StaticModelPreloader.load
    end
  end
end
