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

describe BatchDetailReportGenerator do

  it "should write the provided rows to the csv" do
    problems = []
    problems << ['B1', 'C1', 'Err', '2', 'Hello']
    problems << ['B1', 'C2', 'Warn', 'asdf', 'Msg']
    organiser = double
    expect(organiser).to receive(:detailed_problems).and_return(problems)
    
    BatchDetailReportGenerator.generate_report(organiser, Rails.root.join("tmp/details.csv"))

    rows = CSV.read("tmp/details.csv")
    expect(rows.size).to eq(3)
    expect(rows[0]).to eq(["CYCLE_ID", "Column Name", "Type", "Value", "Message"])
    expect(rows[1]).to eq(['B1', 'C1', 'Err', '2', 'Hello'])
    expect(rows[2]).to eq(['B1', 'C2', 'Warn', 'asdf', 'Msg'])
  end
end
