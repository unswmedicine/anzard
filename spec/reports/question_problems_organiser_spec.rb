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

describe QuestionProblemsOrganiser do

  let(:qpo) do
    qpo = QuestionProblemsOrganiser.new
    qpo.add_problems("q1", "b1", %w(fwa fwb), %w(wa wb), "q1-b1-a")
    qpo.add_problems("q2", "b1", %w(fwc), %w(wc wd), "q2-b1-a")
    qpo.add_problems("q3", "b1", %w(fwe fwf), [], "q3-b1-a")
    qpo.add_problems("q1", "b2", %w(fwa), %w(wa), "q1-b2-a")
    qpo.add_problems("q2", "b2", %w(fwc fwd), %w(wd), "q2-b2-a")
    qpo.add_problems("q3", "b2", [], %w(we), "q3-b2-a")
    qpo
  end

  it "for aggregated report, takes errors and warnings and aggregates them by question and error message" do
    summary = qpo.summary_problems_as_table
    summary.should be_a(Array)
    summary.size.should == 16

    summary[0].should eq(['Cycle IDs with problems', 'Type of Problem', 'Data Items', 'Query'])
    summary[1].should eq(['b1', 'Error',   'q1', 'fwa'])
    summary[2].should eq(['',   'Error',   'q1', 'fwb'])
    summary[3].should eq(['',   'Error',   'q2', 'fwc'])
    summary[4].should eq(['',   'Error',   'q3', 'fwe'])
    summary[5].should eq(['',   'Error',   'q3', 'fwf'])
    summary[6].should eq(['',   'Warning', 'q1', 'wa'])
    summary[7].should eq(['',   'Warning', 'q1', 'wb'])
    summary[8].should eq(['',   'Warning', 'q2', 'wc'])
    summary[9].should eq(['',   'Warning', 'q2', 'wd'])

    summary[10].should eq(['b2', 'Error',   'q1', 'fwa'])
    summary[11].should eq(['',   'Error',   'q2', 'fwc'])
    summary[12].should eq(['',   'Error',   'q2', 'fwd'])
    summary[13].should eq(['',   'Warning', 'q1', 'wa'])
    summary[14].should eq(['',   'Warning', 'q2', 'wd'])
    summary[15].should eq(['',   'Warning', 'q3', 'we'])
  end

  it "For detailed report it takes errors and warnings orders them by cycle id, question and error message" do
    details = qpo.detailed_problems
    details.should be_a(Array)
    details.size.should == 15
    details[0].should eq(['b1', 'q1', 'Error', 'q1-b1-a', 'fwa'])
    details[1].should eq(['b1', 'q1', 'Error', 'q1-b1-a', 'fwb'])
    details[2].should eq(['b1', 'q1', 'Warning', 'q1-b1-a', 'wa'])
    details[3].should eq(['b1', 'q1', 'Warning', 'q1-b1-a', 'wb'])

    details[4].should eq(['b1', 'q2', 'Error', 'q2-b1-a', 'fwc'])
    details[5].should eq(['b1', 'q2', 'Warning', 'q2-b1-a', 'wc'])
    details[6].should eq(['b1', 'q2', 'Warning', 'q2-b1-a', 'wd'])

    details[7].should eq(['b1', 'q3', 'Error', 'q3-b1-a', 'fwe'])
    details[8].should eq(['b1', 'q3', 'Error', 'q3-b1-a', 'fwf'])

    details[9].should eq(['b2', 'q1', 'Error', 'q1-b2-a', 'fwa'])
    details[10].should eq(['b2', 'q1', 'Warning', 'q1-b2-a', 'wa'])

    details[11].should eq(['b2', 'q2', 'Error', 'q2-b2-a', 'fwc'])
    details[12].should eq(['b2', 'q2', 'Error', 'q2-b2-a', 'fwd'])
    details[13].should eq(['b2', 'q2', 'Warning', 'q2-b2-a', 'wd'])

    details[14].should eq(['b2', 'q3', 'Warning', 'q3-b2-a', 'we'])
  end

end