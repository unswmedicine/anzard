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

class ConfigurationItem < ApplicationRecord

  YEAR_OF_REGISTRATION_START = "YearOfRegStart"
  YEAR_OF_REGISTRATION_END = "YearOfRegEnd"

  validates_presence_of(:name)
  validates_presence_of(:configuration_value)

  def self.year_of_registration_range(capturesystem)
    start = ConfigurationItem.find_by_name!("#{capturesystem.name}_#{YEAR_OF_REGISTRATION_START}").configuration_value.to_i
    finish = ConfigurationItem.find_by_name!("#{capturesystem.name}_#{YEAR_OF_REGISTRATION_END}").configuration_value.to_i
    (start..finish).to_a
  end
end
