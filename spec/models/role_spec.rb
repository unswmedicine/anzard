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

describe Role do
  describe "Associations" do
    it { should have_many(:users) }
  end
  
  describe "Scopes" do
    describe "By name" do
      it "should order the roles by name and include all roles" do
        r1 = Role.create(:name => "bcd")
        r2 = Role.create(:name => "aaa")
        r3 = Role.create(:name => "abc")
        Role.by_name.should eq([r2, r3, r1])
      end
    end
  end
    
  describe "Validations" do
    it { should validate_presence_of(:name) }

    it "should reject duplicate names" do
      Role.create!(name: "abc")
      with_duplicate_name = Role.new(name: "abc")
      with_duplicate_name.should_not be_valid
    end

    it "should reject duplicate names identical except for case" do
      Role.create!(name: "ABC")
      with_duplicate_name = Role.new(name: "abc")
      with_duplicate_name.should_not be_valid
    end
  end


end
