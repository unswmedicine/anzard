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

# Helper class which generates human-readable descriptions of the range rules
class NumberRangeFormatter

  include ActionView::Helpers::NumberHelper

  attr_accessor :question

  def initialize(question)
    self.question = question
  end

  def range_text(prefix)
    if question.validate_number_range?
      min = question.number_min
      max = question.number_max
      if min && max
        base = "#{prefix} between #{format_number(min)} and #{format_number(max)}"
      elsif min
        base = "#{prefix} at least #{format_number(min)}"
      else
        base = "#{prefix} a maximum of #{format_number(max)}"
      end
      question.number_unknown ? "#{base} or #{question.number_unknown} for unknown" : base
    else
      nil
    end
  end

  def format_number(decimal)
    number_with_precision(decimal, :precision => 10, :strip_insignificant_zeros => true)
  end

end