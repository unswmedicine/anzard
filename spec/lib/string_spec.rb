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

describe String do
  describe 'is_number?' do
    it 'should recognise unsigned integer strings as numbers' do
      expect('0'.is_number?).to eq true
      expect('1'.is_number?).to eq true
      expect('10'.is_number?).to eq true
      expect('100'.is_number?).to eq true
      expect('010'.is_number?).to eq true
    end

    it 'should recognise negative integer strings as numbers' do
      expect('-0'.is_number?).to eq true
      expect('-1'.is_number?).to eq true
      expect('-10'.is_number?).to eq true
      expect('-100'.is_number?).to eq true
      expect('-010'.is_number?).to eq true
    end

    it 'should recognise positive integer strings as numbers' do
      expect('+0'.is_number?).to eq true
      expect('+1'.is_number?).to eq true
      expect('+10'.is_number?).to eq true
      expect('+100'.is_number?).to eq true
      expect('+010'.is_number?).to eq true
    end

    it 'should recognise unsigned decimal strings as numbers' do
      expect('0.0'.is_number?).to eq true
      expect('1.0'.is_number?).to eq true
      expect('10.5'.is_number?).to eq true
      expect('100.10'.is_number?).to eq true
      expect('010.010'.is_number?).to eq true
    end

    it 'should recognise negative decimal strings as numbers' do
      expect('-0.0'.is_number?).to eq true
      expect('-1.0'.is_number?).to eq true
      expect('-10.5'.is_number?).to eq true
      expect('-100.10'.is_number?).to eq true
      expect('-010.010'.is_number?).to eq true
    end

    it 'should recognise positive decimal strings as numbers' do
      expect('-0.0'.is_number?).to eq true
      expect('-1.0'.is_number?).to eq true
      expect('-10.5'.is_number?).to eq true
      expect('-100.10'.is_number?).to eq true
      expect('-010.010'.is_number?).to eq true
    end

    it 'should not recognise non-numerical strings as numbers' do
      expect('a'.is_number?).to eq false
      expect('o'.is_number?).to eq false
      expect('one'.is_number?).to eq false
      expect('5b'.is_number?).to eq false
      expect('b5'.is_number?).to eq false
      expect('1.a'.is_number?).to eq false
      expect('1.1.1'.is_number?).to eq false
      expect('2e-36'.is_number?).to eq false
      expect('2-36'.is_number?).to eq false
    end

    it 'should not recognise rational numbers as numbers' do
      expect('2/1'.is_number?).to eq false
      expect('0/1'.is_number?).to eq false
      expect('1/1'.is_number?).to eq false
    end

    it 'should not recognise hexadecimal numbers as numbers' do
      expect('0x7a'.is_number?).to eq false
    end

    it 'should not recognise binary numbers as numbers' do
      expect('0b1111010'.is_number?).to eq false
    end
  end
end