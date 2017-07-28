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

# Utility class for storing the details of a validation failure for a batch upload
class QuestionProblem

  attr_accessor :question_code
  attr_accessor :message
  attr_accessor :cycle_ids
  attr_accessor :type

  def initialize(question_code, message, type)
    self.question_code = question_code
    self.message = message
    self.type = type
    self.cycle_ids = []
  end

  def add_cycle_id(code)
    cycle_ids << code
  end

end