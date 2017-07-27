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

describe BatchSummaryReportGenerator do

  it "should create a pdf in the specified path" do
    batch_file = create(:batch_file)
    organiser = double
    organiser.should_receive(:aggregated_by_question_and_message).and_return([["row1", "row1"], ["row2", "row2"]])
    BatchSummaryReportGenerator.generate_report(batch_file, organiser, Rails.root.join("tmp/summary.pdf"))
    File.exist?("tmp/summary.pdf").should be true
  end
end
