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

  attr_accessor :aggregated_problems
  attr_accessor :raw_problems

  def initialize
    self.aggregated_problems = {}
    self.raw_problems = []
  end

  def add_problems(question_code, cycle_id, fatal_warnings, warnings, answer_value)
    fatal_warnings.each { |fw| add_problem(question_code, cycle_id, fw, "Error", answer_value) }
    warnings.each { |w| add_problem(question_code, cycle_id, w, "Warning", answer_value) }
  end


  # organise the aggregated problems for display in the summary report - for each problem there's two rows
  # the first row is the question, problem type, message and count of problem records
  # the second row is a comma separated list of cycle ids that have the problem
  def aggregated_by_question_and_message
    problem_records = aggregated_problems.values.collect(&:values).flatten.sort_by { |prob| [ prob.question_code, prob.message ] }
    table = []
    table << ['Column', 'Type', 'Message', 'Number of records']
    problem_records.each do |problem|
      table << [problem.question_code, problem.type, problem.message, problem.cycle_ids.size.to_s]
      table << ["", "", problem.cycle_ids.join(", "), ""]
    end
    table
  end

  # sort the problems by cycle id, column name and message
  def detailed_problems
    raw_problems.sort_by { |prob| [ prob[0], prob[1], prob[4] ] }
  end


  private

  def add_problem(question_code, cycle_id, message, type, answer_value)
    # for the aggregated report, we count up unique errors by question and error message and keep track of which cycle ids have those errors
    aggregated_problems[question_code] = {} unless aggregated_problems.has_key?(question_code)
    problems_for_question_code = aggregated_problems[question_code]

    problems_for_question_code[message] = QuestionProblem.new(question_code, message, type) unless problems_for_question_code.has_key?(message)
    problem_object = problems_for_question_code[message]

    problem_object.add_cycle_id(cycle_id)

    #for the detail report, splat out the problems into one record per cycle-code / question-code / error message
    #into to an array of arrays, containing: cycle-code, question-code, problem-type, value, message
    raw_problems << [cycle_id, question_code, type, answer_value, message]
  end

end