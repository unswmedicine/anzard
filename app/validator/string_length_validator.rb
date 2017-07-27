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

class StringLengthValidator

  def self.validate(question, answer_value)
    return [true, nil] unless question.validate_string_length?
    return [true, nil] if answer_value.blank?

    if question.string_min
      return [false, message(question)] if answer_value.length < question.string_min
    end
    if question.string_max
      return [false, message(question)] if answer_value.length > question.string_max
    end
    return [true, nil]
  end

  private
  def self.message(question)
    StringLengthFormatter.new(question).range_text("Answer should be")
  end
end