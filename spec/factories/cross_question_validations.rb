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
  factory :cross_question_validation do
    association :question
    association :related_question, factory: :question
    error_message { "err" }
    #We are using a sequence that doesn't sequence here because there is a name collision with Rake::DSL.rule
    sequence(:rule) { 'comparison' }
    operator { '==' }
    constant { 0 }
    set_operator { nil }
    set { nil }
    conditional_operator { nil }
    conditional_constant { nil }
    conditional_set_operator { nil }
    conditional_set { nil }
    after(:create) do |survey|
      StaticModelPreloader.load
    end

    #Comparisons
    factory :cqv_comparison do
      sequence(:rule) { 'comparison' }
      operator { '==' }
    end

    #Implecations
    factory :cqv_present_implies_constant do
      sequence(:rule) { 'present_implies_constant' }
      operator { "==" }
      constant { -1 }
    end

    factory :cqv_const_implies_const do
      sequence(:rule) { 'const_implies_const' }
      conditional_operator { "!=" }
      conditional_constant { 0 }
      operator { ">" }
      constant { 0 }
    end

    factory :cqv_const_implies_one_of_const do
      sequence(:rule) { 'const_implies_one_of_const' }
      conditional_operator { "==" }
      conditional_constant { -1 }
      operator { "==" }
      constant { -1 }
    end

    factory :cqv_const_implies_set do
      sequence(:rule) { 'const_implies_set' }
      conditional_operator { "!=" }
      conditional_constant { 0 }
      set_operator { "included" }
      set { [1, 3, 5, 7] }
    end

    factory :cqv_present_implies_present do
      sequence(:rule) { 'present_implies_present' }
      constant { nil }
    end

    factory :cqv_const_implies_present do
      sequence(:rule) { 'const_implies_present' }
      operator { "==" }
      constant { -1 }
    end

    factory :cqv_set_implies_present do
      sequence(:rule) { 'set_implies_present' }
      set_operator { "range" }
      set { [2, 7] }
    end

    factory :cqv_set_implies_set do
      sequence(:rule) { 'set_implies_set' }
      conditional_set_operator { "included" }
      conditional_set { [2, 4, 6, 8] }
      set_operator { "included" }
      set { [1, 3, 5, 7] }
    end

    factory :cqv_blank_if_const do
      sequence(:rule) { 'blank_if_const' }
      conditional_operator { "==" }
      conditional_constant { -1 }
    end

    factory :cqv_present_if_const do
      sequence(:rule) { 'present_if_const' }
      conditional_operator { "==" }
      conditional_constant { -1 }
    end

    factory :cqv_multi_hours_date_to_date do
      sequence(:rule) { 'multi_hours_date_to_date' }
      operator { '<=' }
    end

    factory :cqv_multi_compare_datetime_quad do
      sequence(:rule) { 'multi_compare_datetime_quad' }
      operator { '<=' }
    end
  end
end
