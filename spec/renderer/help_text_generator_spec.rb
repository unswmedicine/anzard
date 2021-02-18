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

describe HelpTextGenerator do
  describe "Generating format hint for display" do
    it "should return nil for Date, Time and Choice type questions" do
      [Question::TYPE_DATE, Question::TYPE_TIME, Question::TYPE_CHOICE].each do |type|
        q = create(:question, question_type: type)
        expect(HelpTextGenerator.new(q).help_text).to be_nil
      end
    end

    describe "Text type questions" do
      it "should return simple 'text' hint for question without range limits" do
        expect(help_text(question_type: Question::TYPE_TEXT)).to eq("Text")
      end
      it "should return hint with size details for question with range limits (both min and max)" do
        expect(help_text(question_type: Question::TYPE_TEXT, string_min: 10, string_max: 25)).to eq("Text between 10 and 25 characters")
      end
      it "should return hint with size details for question with range limits (both min and max the same)" do
        expect(help_text(question_type: Question::TYPE_TEXT, string_min: 10, string_max: 10)).to eq("Text 10 characters")
      end
      it "should return hint with size details for question with range limits (min only)" do
        expect(help_text(question_type: Question::TYPE_TEXT, string_min: 10, string_max: nil)).to eq("Text at least 10 characters")
      end
      it "should return hint with size details for question with range limits (max only)" do
        expect(help_text(question_type: Question::TYPE_TEXT, string_min: nil, string_max: 25)).to eq("Text a maximum of 25 characters")
      end
    end

    describe "Integer type questions" do
      it "should return simple 'number' hint for question without range limits" do
        expect(help_text(question_type: Question::TYPE_INTEGER, number_min: nil, number_max: nil, number_unknown: nil)).to eq("Number")
      end
      it "should return hint with size details for question with range limits (both min and max)" do
        expect(help_text(question_type: Question::TYPE_INTEGER, number_min: 10, number_max: 25, number_unknown: nil)).to eq("Number between 10 and 25")
      end
      it "should return hint with size details for question with range limits (min only)" do
        expect(help_text(question_type: Question::TYPE_INTEGER, number_min: 10, number_max: nil, number_unknown: nil)).to eq("Number at least 10")
      end
      it "should return hint with size details for question with range limits (max only)" do
        expect(help_text(question_type: Question::TYPE_INTEGER, number_min: nil, number_max: 25, number_unknown: nil)).to eq("Number a maximum of 25")
      end
      it "should return hint with size details for question with range limits (both min and max) with unknown" do
        expect(help_text(question_type: Question::TYPE_INTEGER, number_min: 10, number_max: 25, number_unknown: 99)).to eq("Number between 10 and 25 or 99 for unknown")
      end
      it "should return hint with size details for question with range limits (min only) with unknown" do
        expect(help_text(question_type: Question::TYPE_INTEGER, number_min: 10, number_max: nil, number_unknown: 99)).to eq("Number at least 10 or 99 for unknown")
      end
      it "should return hint with size details for question with range limits (max only) with unknown" do
        expect(help_text(question_type: Question::TYPE_INTEGER, number_min: nil, number_max: 25, number_unknown: 99)).to eq("Number a maximum of 25 or 99 for unknown")
      end
    end

    describe "Decimal type questions" do
      it "should return simple 'number' hint for question without range limits" do
        expect(help_text(question_type: Question::TYPE_DECIMAL, number_min: nil, number_max: nil, number_unknown: nil)).to eq("Decimal number")
      end
      it "should return hint with size details for question with range limits (both min and max)" do
        expect(help_text(question_type: Question::TYPE_DECIMAL, number_min: 10, number_max: 25.3, number_unknown: nil)).to eq("Decimal number between 10 and 25.3")
      end
      it "should return hint with size details for question with range limits (min only)" do
        expect(help_text(question_type: Question::TYPE_DECIMAL, number_min: 10, number_max: nil, number_unknown: nil)).to eq("Decimal number at least 10")
      end
      it "should return hint with size details for question with range limits (max only)" do
        expect(help_text(question_type: Question::TYPE_DECIMAL, number_min: nil, number_max: 25.3, number_unknown: nil)).to eq("Decimal number a maximum of 25.3")
      end
      it "should return hint with size details for question with range limits (both min and max) with unknown" do
        expect(help_text(question_type: Question::TYPE_DECIMAL, number_min: 10, number_max: 25.3, number_unknown: 99)).to eq("Decimal number between 10 and 25.3 or 99 for unknown")
      end
      it "should return hint with size details for question with range limits (min only) with unknown" do
        expect(help_text(question_type: Question::TYPE_DECIMAL, number_min: 10, number_max: nil, number_unknown: 99)).to eq("Decimal number at least 10 or 99 for unknown")
      end
      it "should return hint with size details for question with range limits (max only) with unknown" do
        expect(help_text(question_type: Question::TYPE_DECIMAL, number_min: nil, number_max: 25.3, number_unknown: 99)).to eq("Decimal number a maximum of 25.3 or 99 for unknown")
      end
    end
  end
end

def help_text(question_attrs)
  q = create(:question, question_attrs)
  HelpTextGenerator.new(q).help_text
end