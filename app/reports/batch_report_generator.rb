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

class BatchReportGenerator

  attr_accessor :batch_file

  def initialize(batch_file)
    self.batch_file = batch_file
  end

  def generate_reports
    organiser = batch_file.organised_problems

    summary_file_path = File.join(APP_CONFIG['batch_reports_path'], "#{batch_file.id}-summary.pdf")
    BatchSummaryReportGenerator.generate_report(batch_file, organiser, summary_file_path)
    batch_file.summary_report_path = summary_file_path

    unless batch_file.success?
      detail_file_path = File.join(APP_CONFIG['batch_reports_path'], "#{batch_file.id}-details.csv")
      BatchDetailReportGenerator.generate_report(organiser, detail_file_path)
      batch_file.detail_report_path = detail_file_path
    end
  end

end