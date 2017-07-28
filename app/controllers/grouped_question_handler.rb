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

class GroupedQuestionHandler

  attr_accessor :last_order_within_group
  attr_accessor :last_group_number
  attr_accessor :highest_group_to_show
  attr_accessor :question_ids_to_answers

  def initialize(group_name, questions_for_group, question_ids_to_answers)
    self.question_ids_to_answers = question_ids_to_answers
    self.last_order_within_group = questions_for_group.collect(&:order_within_group).sort.last
    self.last_group_number = questions_for_group.collect(&:group_number).sort.last
    answered_qs = []
    questions_for_group.each do |q|
      answered_qs << q if question_ids_to_answers[q.id] && question_ids_to_answers[q.id].answer_value_set?
    end
    self.highest_group_to_show = answered_qs.collect(&:group_number).sort.last
    self.highest_group_to_show = 1 unless self.highest_group_to_show
  end

  def hide_group?(question)
    question.group_number > self.highest_group_to_show
  end

  def show_add_link?(question)
    return false unless question.group_number >= self.highest_group_to_show && question.group_number < self.last_group_number
    question.order_within_group == self.last_order_within_group
  end

  def max_multi?(question)
    # last question-group's last question?
    question.group_number == self.last_group_number and question.order_within_group == self.last_order_within_group
  end
end
