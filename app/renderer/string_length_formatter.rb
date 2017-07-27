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

# Helper class which generates human-readable descriptions of the string length range rules
class StringLengthFormatter
  include ActionView::Helpers::NumberHelper

  attr_accessor :question

  def initialize(question)
    self.question = question
  end

  def range_text(prefix)
    min = question.string_min
    max = question.string_max
    if min && max
      if min == max
        "#{prefix} #{min} characters"
      else
        "#{prefix} between #{min} and #{max} characters"
      end
    elsif min
      "#{prefix} at least #{min} characters"
    else
      "#{prefix} a maximum of #{max} characters"
    end
  end
end