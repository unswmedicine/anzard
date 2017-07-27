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

describe QuestionProblem do
  it "can have more cycle ids added to it" do
    qp = QuestionProblem.new("code", "msg", "error")
    qp.question_code.should == "code"
    qp.message.should == "msg"
    qp.type.should == "error"
    qp.cycle_ids.should be_empty
    qp.add_cycle_id("abc")
    qp.add_cycle_id("def")
    qp.cycle_ids.should eq(["abc", "def"])
  end
end