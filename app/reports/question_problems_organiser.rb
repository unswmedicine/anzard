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

# Class which organises the validation failures for a batch upload into the structures needed for generating the reports
class QuestionProblemsOrganiser
  attr_accessor :raw_problems

  def initialize
    self.raw_problems = []
  end

  def add_problems(question_code, cycle_id, fatal_warnings, warnings, answer_value)
    fatal_warnings.each { |fw| add_problem(question_code, cycle_id, fw, "Error", answer_value) }
    warnings.each { |w| add_problem(question_code, cycle_id, w, "Warning", answer_value) }
  end

  # sort the problems by cycle id, column name and message
  def detailed_problems
    raw_problems.sort_by { |prob| [ prob[0], prob[1], prob[4] ] }
  end

  def summary_problems_as_table
    problems_table = [['Cycle IDs with problems', 'Type of Problem', 'Data Items', 'Query']]
    added_cycle_ids = []
    summary_problems.each do |problem|
      cycle_id = problem[0]
      # Only list cycle ID in first row for problems grouped by cycle id
      if added_cycle_ids.include?(cycle_id)
        cycle_id = ""
      else
        added_cycle_ids << cycle_id
      end
      problems_table << [cycle_id, problem[2], problem[1], problem[4]]
    end
    problems_table
  end

  def organise(r, survey_configuration)
    # Get original cycle ID (cycle ID without site code) for display in reports to user
    cycle_id_without_site_code = r.cycle_id
    concatenated_site_code = '_' + r.clinic.site_code.to_s
    if r.cycle_id.end_with?(concatenated_site_code)
      cycle_id_without_site_code = r.cycle_id.slice(0, r.cycle_id.length - concatenated_site_code.length)
    end

    r.answers.each do |answer|
      self.add_problems(answer.question.code, cycle_id_without_site_code, answer.fatal_warnings, answer.warnings(survey_configuration), answer.format_for_csv)
    end
    r.missing_mandatory_questions.each do |question|
      self.add_problems(question.code, cycle_id_without_site_code, ['This question is mandatory'], [], '')
    end

    r.valid? # we have to call this to trigger errors getting populated
    unless r.errors.empty?
      # Replace auto-concatenated cycle ID with original cycle ID for display of record validation errors
      response_error_msgs = r.errors.full_messages
      response_error_msgs.each do |msg|
        msg.gsub!(r.cycle_id, cycle_id_without_site_code)
      end
      self.add_problems(BatchFile::COLUMN_CYCLE_ID, cycle_id_without_site_code, response_error_msgs, [], cycle_id_without_site_code)
    end
  end

  private

  # sort the problems by cycle id, problem type, column name and message
  def summary_problems
    raw_problems.sort_by{ |prob| [ prob[0], prob[2], prob[1], prob[4] ] }
  end

  def add_problem(question_code, cycle_id, message, type, answer_value)
    # for the summary report, we group problems by cycle-code

    #for the detail report, splat out the problems into one record per cycle-code / question-code / error message
    #into to an array of arrays, containing: cycle-code, question-code, problem-type, value, message
    raw_problems << [cycle_id, question_code, type, answer_value, message]
  end

end