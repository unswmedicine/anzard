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

describe DateInputHandler do

  describe "Accepting string input" do
    describe "should be valid with valid dates" do
      it { should_accept("2012-12-25") }
      it { should_accept("2012-01-01") }
      it { should_accept("1999-1-1") }
      it { should_accept("25/12/2012") }
      it { should_accept("1/2/1999") }
    end

    describe "should be invalid with invalid dates" do
      it { should_reject("asdf") }
      it { should_reject("2012") }
      it { should_reject("asdf-11-11") }
      it { should_reject("junk") }
      it { should_reject("2012-01-") }
      it { should_reject("05-02-2011") } #we don't allow this format
      it { should_reject("05/22/2011") } #american date
      it { should_reject("30/2/2011") } #non existent
      it { should_reject("/22/2011") } #part missing
      it { should_reject("1//2011") } #part missing
      it { should_reject("12-1-1") } # reject years less than 1900
      it { should_reject("1899-1-1") } # reject years less than 1900
    end
  end

  describe "Accepting hash input" do
    it "should be valid when all 3 fields supplied" do
      dih = DateInputHandler.new(ActiveSupport::HashWithIndifferentAccess.new ({day: "1", month: "12", year: "2000"}))
      expect(dih).to be_valid
      expect(dih.to_date).to eq(Date.parse("2000-12-01"))
    end

    it "should be invalid if a field is missing - month missing" do
      dih = DateInputHandler.new(ActiveSupport::HashWithIndifferentAccess.new ({day: "1", month: "", year: "2000"}))
      expect(dih).to_not be_valid
      raw = dih.to_raw
      expect(raw).to be_a(Hash)
      expect(raw[:day]).to eq "1"
      expect(raw[:month]).to eq ""
      expect(raw[:year]).to eq "2000"
    end

    it "should be invalid if a field is missing - year missing" do
      dih = DateInputHandler.new(ActiveSupport::HashWithIndifferentAccess.new ({day: "1", month: "12", year: ""}))
      expect(dih).to_not be_valid
      raw = dih.to_raw
      expect(raw).to be_a(Hash)
      expect(raw[:day]).to eq "1"
      expect(raw[:month]).to eq "12"
      expect(raw[:year]).to eq ""
    end

    it "should be invalid if date does not exist" do
      dih = DateInputHandler.new(ActiveSupport::HashWithIndifferentAccess.new ({day: "30", month: "2", year: "2000"}))
      expect(dih).to_not be_valid
      raw = dih.to_raw
      expect(raw).to be_a(Hash)
      expect(raw[:day]).to eq "30"
      expect(raw[:month]).to eq "2"
      expect(raw[:year]).to eq "2000"
    end
  end

  describe "Accepting date input" do
    it "should accept it as is since it must be valid" do
      date = Date.parse("2011-12-12")
      dih = DateInputHandler.new(date)
      expect(dih).to be_valid
      expect(dih.to_date).to be(date)
    end
  end

  describe "Refuses to handle other types of input" do
    it "should throw an error on other types" do
      expect(lambda { DateInputHandler.new(123) }).to raise_error("DateInputHandler can only handle String, Hash and Date input")
    end
  end

  describe "Refuses to answer to_raw if valid" do
    it "should throw an error" do
      dih = DateInputHandler.new("2012-12-22")
      expect(lambda { dih.to_raw }).to raise_error("Date is valid, cannot call to_raw, you should check valid? first")
    end
  end

  describe "Refuses to answer to_date if invalid" do
    it "should throw an error" do
      dih = DateInputHandler.new("asdf")
      expect(lambda { dih.to_date }).to raise_error("Date is not valid, cannot call to_date, you should check valid? first")
    end
  end

  def should_accept(string)
    dih = DateInputHandler.new(string)
    expect(dih).to be_valid
    expect(dih.to_date).to eq(Date.parse(string))
  end

  def should_reject(string)
    dih = DateInputHandler.new(string)
    expect(dih).to_not be_valid
    expect(dih.to_raw).to eq(string)
  end
end

