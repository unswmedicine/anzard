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

describe Section do
  describe "Associations" do
    it { should belong_to :survey }
    it { should have_many :questions }
  end
  describe "Validations" do
    it { should validate_presence_of(:name) }
    describe "order" do
      it { should validate_presence_of :section_order }
      it "is unique within a survey" do
        first_section = create :section
        second_section = build :section, survey: first_section.survey, section_order: first_section.section_order
        expect(second_section).to_not be_valid

        section_in_another_survey = build :section, section_order: first_section.section_order
        expect(section_in_another_survey).to be_valid
      end
    end
  end

  describe "Am I the last section method" do
    it "should return true only for the section with highest index" do
      survey1 = create(:survey)
      survey2 = create(:survey)
      sec2 = create(:section, survey: survey1, section_order: 2)
      sec3 = create(:section, survey: survey1, section_order: 3)
      sec4 = create(:section, survey: survey2, section_order: 4)
      sec1 = create(:section, survey: survey1, section_order: 1)

      expect(sec1.last?).to be false
      expect(sec2.last?).to be false
      expect(sec3.last?).to be true
      expect(sec4.last?).to be true
    end
  end
end
