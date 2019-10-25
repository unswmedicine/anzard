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

require 'rails_helper'

describe SurveyConfiguration do
  describe "Associations" do
    it { should belong_to :survey }
  end

  describe "Validations" do
    it { should validate_numericality_of(:start_year_of_treatment).is_greater_than(1900).is_less_than(2100).only_integer.allow_nil }
    it { should validate_numericality_of(:end_year_of_treatment).is_greater_than(1900).is_less_than(2100).only_integer.allow_nil }
  end
end
