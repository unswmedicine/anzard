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

# Specs in this file have access to a helper object that includes
# the ResponsesHelper. For example:
#
# describe ResponsesHelper, :type => :helper do
#   describe "string concat" do
#     it "concats two strings with spaces" do
#       helper.concat_strings("this","that").should == "this that"
#     end
#   end
# end

describe ResponsesHelper, :type => :helper do
  describe "Generating response page titles" do
    it "should string together survey, cycle id and year of reg" do
      response = create(:response, cycle_id: "Bcdef", year_of_registration: 2015, survey: create(:survey, name: "My Survey"))
      helper.response_title(response).should eq("My Survey - Cycle ID Bcdef - Year of Treatment 2015")
    end
  end
end
