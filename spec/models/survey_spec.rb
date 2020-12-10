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

describe Survey do
  describe "Associations" do
    it { should have_many :responses }
    it { should have_many :sections }
    it { should have_one :survey_configuration }
  end
  describe "Validations" do
    before :each do
      create :survey
    end
    it { should validate_presence_of(:name) }
    it { should validate_uniqueness_of(:name) }
  end

  describe :ordered_questions do
    it "should retrieve questions ordered by section.order, question.order" do
      survey = create(:survey)
      s2 = create(:section, survey: survey, section_order: 2)
      s1 = create(:section, survey: survey, section_order: 1)
      q1b = create(:question, question: 'q1b', section: s1, question_order: 2)
      q1a = create(:question, question: 'q1a', section: s1, question_order: 1)
      q2a = create(:question, question: 'q2a', section: s2, question_order: 1)
      q2b = create(:question, question: 'q2b', section: s2, question_order: 2)

      expected = %w{q1a q1b q2a q2b}
      actual = survey.ordered_questions.map { |q| q.question }

      expect(actual).to eq expected
    end
  end

  describe "Finding the next section after a given section" do
    it "should find the next one based on order" do
      survey1 = create(:survey)
      sec2 = create(:section, survey: survey1, section_order: 2)
      sec3 = create(:section, survey: survey1, section_order: 3)
      sec1 = create(:section, survey: survey1, section_order: 1)

      expect(survey1.section_id_after(sec1.id)).to eq(sec2.id)
      expect(survey1.section_id_after(sec2.id)).to eq(sec3.id)
    end

    it "should raise error on last section" do
      survey1 = create(:survey)
      sec2 = create(:section, survey: survey1, section_order: 2)
      sec3 = create(:section, survey: survey1, section_order: 3)
      sec1 = create(:section, survey: survey1, section_order: 1)

      expect(lambda { survey1.section_id_after(sec3.id) }).to raise_error("Tried to call section_id_after on last section")
    end

    it "should raise error when section not found" do
      survey1 = create(:survey)
      sec2 = create(:section, survey: survey1, section_order: 2)
      sec1 = create(:section, survey: survey1, section_order: 1)

      expect(lambda { survey1.section_id_after(123434) }).to raise_error("Didn't find any section with id 123434 in this survey")
    end
  end

  describe "Get question with code" do
    before(:each) do
      @survey = create(:survey)
      @q1 = create(:question, code: 'qOne', section: create(:section, survey: @survey))
      @q2 = create(:question, code: 'QTwo', section: create(:section, survey: @survey))
      other_q1 = create(:question, code: 'qOne')
    end

    it "should find the question, even with mismatching case" do
      expect(@survey.question_with_code("qOne")).to eq(@q1)
      expect(@survey.question_with_code("QOne")).to eq(@q1)
      expect(@survey.question_with_code("QonE")).to eq(@q1)
    end

    it "should return the same object when asking twice" do
      q = @survey.question_with_code("qOne")
      expect(@survey.question_with_code("qOne")).to be(q)
    end

    it "should return nil if no such question exists in the survey" do
      expect(@survey.question_with_code("blah")).to be_nil
    end

    it "should return nil if nil or blank passed in" do
      expect(@survey.question_with_code("")).to be_nil
      expect(@survey.question_with_code(nil)).to be_nil
    end
  end


end
