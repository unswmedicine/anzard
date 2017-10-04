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

class QuestionOption < ApplicationRecord
  belongs_to :question

  validates_presence_of :question_id
  validates_presence_of :option_value
  validates_presence_of :label
  validates_presence_of :option_order
  validates_uniqueness_of :option_order, scope: :question_id

  before_save :downcase_option_value

  def display_value
    "(#{option_value}) #{label}"
  end

  private

  def downcase_option_value
    option_value.downcase!
  end
end
