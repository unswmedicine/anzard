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

class NumberRangeValidator

  def self.validate(question, answer_value)
    return [true, nil] unless question.validate_number_range?
    return [true, nil] if answer_value.nil?

    if question.number_unknown
      return [true, nil] if answer_value == question.number_unknown
    end
    if question.number_min
      return [false, message(question)] if answer_value < question.number_min
    end
    if question.number_max
      return [false, message(question)] if answer_value > question.number_max
    end
    return [true, nil]
  end

  def self.message(question)
    NumberRangeFormatter.new(question).range_text("Answer should be")
  end

end