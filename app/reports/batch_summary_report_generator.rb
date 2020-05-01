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

class BatchSummaryReportGenerator

  def self.generate_report(batch_file, organiser, file_path)
    Prawn::Document.generate file_path do
      font_size(24)
      text "Validation Report: Summary", :align => :center

      font_size(10)

      move_down 20

      text "Treatment data: #{batch_file.survey.name}"
      text "File name: #{batch_file.file_file_name}"
      text "Date submitted: #{batch_file.created_at}"
      text "Submitted by: #{batch_file.user.full_name}"
      text "Status: #{batch_file.status} (#{batch_file.message})"

      move_down 10
      text "Number of cycles: #{batch_file.record_count}"
      text "Number of cycles with problems: #{batch_file.problem_record_count}"

      move_down 10
      problems_table = organiser.summary_problems_as_table
      if problems_table.size > 1
        table(problems_table, header: true, row_colors: ["FFFFFF", "F0F0F0"], column_widths: {0 => 95, 1 => 65, 2 => 95}) do
          row(0).font_style = :bold
        end
      end

    end
  end
end
