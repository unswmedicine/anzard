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
    expect(summary).to be_a(Array)
    expect(summary.size).to eq 16

    expect(summary[0]).to eq(['Cycle IDs with problems', 'Type of Problem', 'Data Items', 'Query'])
    expect(summary[1]).to eq(['b1', 'Error',   'q1', 'fwa'])
    expect(summary[2]).to eq(['',   'Error',   'q1', 'fwb'])
    expect(summary[3]).to eq(['',   'Error',   'q2', 'fwc'])
    expect(summary[4]).to eq(['',   'Error',   'q3', 'fwe'])
    expect(summary[5]).to eq(['',   'Error',   'q3', 'fwf'])
    expect(summary[6]).to eq(['',   'Warning', 'q1', 'wa'])
    expect(summary[7]).to eq(['',   'Warning', 'q1', 'wb'])
    expect(summary[8]).to eq(['',   'Warning', 'q2', 'wc'])
    expect(summary[9]).to eq(['',   'Warning', 'q2', 'wd'])

    expect(summary[10]).to eq(['b2', 'Error',   'q1', 'fwa'])
    expect(summary[11]).to eq(['',   'Error',   'q2', 'fwc'])
    expect(summary[12]).to eq(['',   'Error',   'q2', 'fwd'])
    expect(summary[13]).to eq(['',   'Warning', 'q1', 'wa'])
    expect(summary[14]).to eq(['',   'Warning', 'q2', 'wd'])
    expect(summary[15]).to eq(['',   'Warning', 'q3', 'we'])
  end

  it "For detailed report it takes errors and warnings orders them by cycle id, question and error message" do
    details = qpo.detailed_problems
    expect(details).to be_a(Array)
    expect(details.size).to eq 15
    expect(details[0]).to eq(['b1', 'q1', 'Error', 'q1-b1-a', 'fwa'])
    expect(details[1]).to eq(['b1', 'q1', 'Error', 'q1-b1-a', 'fwb'])
    expect(details[2]).to eq(['b1', 'q1', 'Warning', 'q1-b1-a', 'wa'])
    expect(details[3]).to eq(['b1', 'q1', 'Warning', 'q1-b1-a', 'wb'])

    expect(details[4]).to eq(['b1', 'q2', 'Error', 'q2-b1-a', 'fwc'])
    expect(details[5]).to eq(['b1', 'q2', 'Warning', 'q2-b1-a', 'wc'])
    expect(details[6]).to eq(['b1', 'q2', 'Warning', 'q2-b1-a', 'wd'])

    expect(details[7]).to eq(['b1', 'q3', 'Error', 'q3-b1-a', 'fwe'])
    expect(details[8]).to eq(['b1', 'q3', 'Error', 'q3-b1-a', 'fwf'])

    expect(details[9]).to eq(['b2', 'q1', 'Error', 'q1-b2-a', 'fwa'])
    expect(details[10]).to eq(['b2', 'q1', 'Warning', 'q1-b2-a', 'wa'])

    expect(details[11]).to eq(['b2', 'q2', 'Error', 'q2-b2-a', 'fwc'])
    expect(details[12]).to eq(['b2', 'q2', 'Error', 'q2-b2-a', 'fwd'])
    expect(details[13]).to eq(['b2', 'q2', 'Warning', 'q2-b2-a', 'wd'])

    expect(details[14]).to eq(['b2', 'q3', 'Warning', 'q3-b2-a', 'we'])
  end

end