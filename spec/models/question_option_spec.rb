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

describe QuestionOption do
  describe "Validations" do
    it { should validate_presence_of(:question_id) }
    it { should validate_presence_of(:option_value) }
    it { should validate_presence_of(:label) }
    it { should validate_presence_of(:option_order) }

    it "should validate that order is unique within a question" do
      first = create(:question_option)
      second = build(:question_option, question: first.question, option_order: first.option_order)
      second.should_not be_valid

      under_different_question = build(:question_option, question: create(:question), option_order: first.option_order)
      under_different_question.should be_valid
    end
  end

  describe "Display value" do
    it "should include value and label" do
      qo = create(:question_option, label: "A label", option_value: "99")
      qo.display_value.should eq("(99) A label")
    end
  end
end
