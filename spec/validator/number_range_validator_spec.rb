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

describe NumberRangeValidator do

  describe "Validating a range with an unknown value" do
    let(:question) { create(:question, number_min: 5, number_max: 15, number_unknown: 99) }

    it "should return true if in range" do
      expect(NumberRangeValidator.validate(question, 5)).to eq([true, nil])
      expect(NumberRangeValidator.validate(question, 5.1)).to eq([true, nil])
      expect(NumberRangeValidator.validate(question, 10)).to eq([true, nil])
      expect(NumberRangeValidator.validate(question, 15)).to eq([true, nil])
    end

    it "should return false it outside range" do
      expect(NumberRangeValidator.validate(question, 4)).to eq([false, "Answer should be between 5 and 15 or 99 for unknown"])
      expect(NumberRangeValidator.validate(question, 4.9)).to eq([false, "Answer should be between 5 and 15 or 99 for unknown"])
      expect(NumberRangeValidator.validate(question, 15.1)).to eq([false, "Answer should be between 5 and 15 or 99 for unknown"])
      expect(NumberRangeValidator.validate(question, 16)).to eq([false, "Answer should be between 5 and 15 or 99 for unknown"])
      expect(NumberRangeValidator.validate(question, -10)).to eq([false, "Answer should be between 5 and 15 or 99 for unknown"])
    end

    it "should return true if equal to unknown value" do
      expect(NumberRangeValidator.validate(question, 99)).to eq([true, nil])
    end
  end

  describe "Validating a range without an unknown value" do
    let(:question) { create(:question, number_min: 5, number_max: 15, number_unknown: nil) }

    it "should return true if in range" do
      expect(NumberRangeValidator.validate(question, 5)).to eq([true, nil])
      expect(NumberRangeValidator.validate(question, 5.1)).to eq([true, nil])
      expect(NumberRangeValidator.validate(question, 10)).to eq([true, nil])
      expect(NumberRangeValidator.validate(question, 15)).to eq([true, nil])
    end

    it "should return false it outside range" do
      expect(NumberRangeValidator.validate(question, 4)).to eq([false, "Answer should be between 5 and 15"])
      expect(NumberRangeValidator.validate(question, 4.9)).to eq([false, "Answer should be between 5 and 15"])
      expect(NumberRangeValidator.validate(question, 15.1)).to eq([false, "Answer should be between 5 and 15"])
      expect(NumberRangeValidator.validate(question, 16)).to eq([false, "Answer should be between 5 and 15"])
      expect(NumberRangeValidator.validate(question, -10)).to eq([false, "Answer should be between 5 and 15"])
    end
  end

  describe "Validating min only with an unknown value" do
    let(:question) { create(:question, number_min: 5, number_max: nil, number_unknown: 1) }

    it "should return true if in range" do
      expect(NumberRangeValidator.validate(question, 5)).to eq([true, nil])
      expect(NumberRangeValidator.validate(question, 5.1)).to eq([true, nil])
      expect(NumberRangeValidator.validate(question, 10)).to eq([true, nil])
      expect(NumberRangeValidator.validate(question, 111111111)).to eq([true, nil])
    end

    it "should return false it outside range" do
      expect(NumberRangeValidator.validate(question, 4)).to eq([false, "Answer should be at least 5 or 1 for unknown"])
      expect(NumberRangeValidator.validate(question, 4.9)).to eq([false, "Answer should be at least 5 or 1 for unknown"])
      expect(NumberRangeValidator.validate(question, -10)).to eq([false, "Answer should be at least 5 or 1 for unknown"])
    end

    it "should return true if equal to unknown value" do
      expect(NumberRangeValidator.validate(question, 1)).to eq([true, nil])
    end
  end

  describe "Validating min only without an unknown value" do
    let(:question) { create(:question, number_min: 5, number_max: nil, number_unknown: nil) }

    it "should return true if in range" do
      expect(NumberRangeValidator.validate(question, 5)).to eq([true, nil])
      expect(NumberRangeValidator.validate(question, 5.1)).to eq([true, nil])
      expect(NumberRangeValidator.validate(question, 10)).to eq([true, nil])
      expect(NumberRangeValidator.validate(question, 111111111)).to eq([true, nil])
    end

    it "should return false it outside range" do
      expect(NumberRangeValidator.validate(question, 4)).to eq([false, "Answer should be at least 5"])
      expect(NumberRangeValidator.validate(question, 4.9)).to eq([false, "Answer should be at least 5"])
      expect(NumberRangeValidator.validate(question, -10)).to eq([false, "Answer should be at least 5"])
    end
  end

  describe "Validating max only with an unknown value" do
    let(:question) { create(:question, number_min: nil, number_max: 15, number_unknown: 1) }

    it "should return true if in range" do
      expect(NumberRangeValidator.validate(question, 5)).to eq([true, nil])
      expect(NumberRangeValidator.validate(question, 14.9)).to eq([true, nil])
      expect(NumberRangeValidator.validate(question, 10)).to eq([true, nil])
      expect(NumberRangeValidator.validate(question, -1111111111)).to eq([true, nil])
    end

    it "should return false it outside range" do
      expect(NumberRangeValidator.validate(question, 15.1)).to eq([false, "Answer should be a maximum of 15 or 1 for unknown"])
      expect(NumberRangeValidator.validate(question, 20)).to eq([false, "Answer should be a maximum of 15 or 1 for unknown"])
      expect(NumberRangeValidator.validate(question, 11111111)).to eq([false, "Answer should be a maximum of 15 or 1 for unknown"])
    end

    it "should return true if equal to unknown value" do
      expect(NumberRangeValidator.validate(question, 1)).to eq([true, nil])
    end
  end

  describe "Validating max only without an unknown value" do
    let(:question) { create(:question, number_min: nil, number_max: 15, number_unknown: nil) }

    it "should return true if in range" do
      expect(NumberRangeValidator.validate(question, 5)).to eq([true, nil])
      expect(NumberRangeValidator.validate(question, 14.9)).to eq([true, nil])
      expect(NumberRangeValidator.validate(question, 10)).to eq([true, nil])
      expect(NumberRangeValidator.validate(question, -1111111111)).to eq([true, nil])
    end

    it "should return false it outside range" do
      expect(NumberRangeValidator.validate(question, 15.1)).to eq([false, "Answer should be a maximum of 15"])
      expect(NumberRangeValidator.validate(question, 20)).to eq([false, "Answer should be a maximum of 15"])
      expect(NumberRangeValidator.validate(question, 11111111)).to eq([false, "Answer should be a maximum of 15"])
    end
  end

  describe "Validating on a question with no range" do
    it "should always return true" do
      question = create(:question, number_min: nil, number_max: nil)
      expect(NumberRangeValidator.validate(question, 2344)).to eq([true, nil])
    end
  end

  describe "Validating a nil answer" do
    it "should always return true" do
      question = create(:question, number_min: 1, number_max: 5)
      #nil does not produce an error
      expect(NumberRangeValidator.validate(question, nil)).to eq([true, nil])
    end
  end
end
