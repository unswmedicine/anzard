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

class TimeInputHandler
  def initialize(input)
    if input.is_a?(String)
      handle_string(input)
    elsif input.is_a?(Hash)
      handle_hash(input)
    elsif input.is_a?(Time)
      @valid = true
      @time = input
    else
      raise "TimeInputHandler can only handle String, Hash and Time input"
    end
  end

  def valid?
    @valid
  end

  def to_time
    raise "Time is not valid, cannot call to_time, you should check valid? first" unless @valid
    @time
  end

  def to_raw
    raise "Time is valid, cannot call to_raw, you should check valid? first" if @valid
    @raw
  end

  private

  def handle_hash(input)
    if input[:hour].blank? || input[:min].blank?
      @raw = input
      @valid = false
    else
      begin
        @time = Time.utc(2000, 1, 1, input[:hour].to_i, input[:min].to_i)
        @valid = true
      rescue ArgumentError
        @raw = input
        @valid = false
      end
    end
  end

  def handle_string(input)
    begin
      t = Time.strptime(input, "%H:%M")
      #strptime accepts 24:00 which we don't want because its kinda ambiguous, so we have to check for it ourselves
      if input.split(":").first == "24"
        @raw = input
        @valid = false
      else
        @time = Time.utc(2000, 1, 1, t.hour, t.min)
        @valid = true
      end
    rescue ArgumentError
      @raw = input
      @valid = false
    end
  end

end