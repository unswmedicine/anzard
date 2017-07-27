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

class PartialDateTimeHash < HashWithIndifferentAccess
  #So rails' black magic with dates and times sucks. Fortunately, if you give the helper methods something that looks
  # like a Date or Time and quacks like one then it will work like one.

  #This hash can be built by passing it a Date, Time, DateTime or regular hash
  #Warning - this will IGNORE the day/month/year for a Time object. use DateTime instead!!!

  fields = [:day, :month, :year, :hour, :min]

  fields.each do |method_name|
    send :define_method, method_name do
      self[method_name].blank? ? nil : self[method_name].to_i
    end
  end

  def initialize(input)
    if input.is_a?(Date)
      super({day: input.day, month: input.month, year: input.year})
    elsif input.is_a?(Time)
      super({min: input.min, hour: input.hour})
    elsif input.is_a?(DateTime)
      super({min: input.min, hour: input.hour, day: input.day, month: input.month, year: input.year})
    else
      super(input)
    end
  end

end