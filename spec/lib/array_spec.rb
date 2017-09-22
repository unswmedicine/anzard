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

require 'rails_helper'

describe Array do
  describe 'contains_non_numerical_string?' do
    NUMERICAL_STRING_SET = %w(0 1 -1 +1 1.5 -1.5 +1.5 0.00 1.00 01 01.00)
    NON_NUMERICAL_STRING_SET = %w(a b c yes no 0x7a 0b1111010 2e-36 2-36 1.a 1.1.1 b5 5b one)

    it 'should return false on empty array' do
      expect([].contains_non_numerical_string?).to eq false
    end

    it 'should return false when array only contains integer or decimal strings' do
      expect(NUMERICAL_STRING_SET.contains_non_numerical_string?).to eq false
    end

    it 'should return true when array contains any non-integer and non-decimal strings' do
      expect(NON_NUMERICAL_STRING_SET.contains_non_numerical_string?).to eq true
      expect(NUMERICAL_STRING_SET.append('a').contains_non_numerical_string?).to eq true
    end

    it 'should return false when array contains only Integer or Float types' do
      expect([0].contains_non_numerical_string?).to eq false
      expect([0.0].contains_non_numerical_string?).to eq false
      expect([0, 0.0, 1, 1.5, -1.5].contains_non_numerical_string?).to eq false
    end
  end

  describe 'downcase!' do
    it 'should downcast all string elements' do
      arr = ['Hello', 'WORLD!', 'test', 1, 0.0, nil]
      arr.downcase!
      expect(arr).to eq(['hello', 'world!', 'test', 1, 0.0, nil])
    end
  end

  describe 'downcase' do
    it 'should return an array of downcast string elements' do
      arr = ['Hello', 'WORLD!', 'test', 1, 0.0, nil]
      downcast_arr = arr.downcase
      expect(arr).to eq(['Hello', 'WORLD!', 'test', 1, 0.0, nil])
      expect(downcast_arr).to eq(['hello', 'world!', 'test', 1, 0.0, nil])
    end

    it 'should return original if no string elements' do
      arr = [1, 0.0, nil]
      downcast_arr = arr.downcase
      expect(arr).to eq([1, 0.0, nil])
      expect(downcast_arr).to eq([1, 0.0, nil])
    end

    it 'should return empty if original empty' do
      arr = []
      downcast_arr = arr.downcase
      expect(arr).to eq([])
      expect(downcast_arr).to eq([])
    end
  end
end