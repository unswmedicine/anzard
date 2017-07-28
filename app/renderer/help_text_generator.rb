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

# Helper class which generates the help text for a question based on the properties of the question
class HelpTextGenerator
  attr_accessor :question

  def initialize(question)
    self.question = question
  end

  def help_text
    if question.type_text?
      help_text_for_text_type
    elsif question.type_integer?
      help_text_for_number_type("Number")
    elsif question.type_decimal?
      help_text_for_number_type("Decimal number")
    else
      nil
    end
  end

  private

  def help_text_for_text_type
    if question.validate_string_length?
      StringLengthFormatter.new(question).range_text("Text")
    else
      "Text"
    end
  end

  def help_text_for_number_type(prefix)
    if question.validate_number_range?
      NumberRangeFormatter.new(question).range_text(prefix)
    else
      prefix
    end
  end
end