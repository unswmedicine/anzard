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

class Array

  # Returns true when array contains string that is not an Integer or Decimal value.
  def contains_non_numerical_string?
    self.each do |item|
      if item.is_a?(String) && !item.is_number?
        return true
      end
    end
    false
  end

  # Downcast all string elements in the array
  def downcase!
    self.replace(self.downcase)
  end

  # Returns a copy with all string elements downcast
  def downcase
    self.map do |elem|
      if elem.is_a?(String)
        elem.downcase
      else
        elem
      end
    end
  end
end