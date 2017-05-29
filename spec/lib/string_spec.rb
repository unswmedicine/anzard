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

  describe 'to_float_if_number' do
    it 'should return a float when passed a valid number' do
      valid_numbers = %w(0 1 -1 +1 1.5 -1.5 +1.5 0.00 1.00 01 01.00)
      valid_numbers.each do |n|
        expect(n.to_float_if_number.is_a? Float).to eq true
      end
    end

    it 'should return the string as provided when it is not a valid number' do
      strings = %w(a b c yes no 0x7a 0b1111010 2e-36 2-36 1.a 1.1.1 b5 5b one)
      strings.each do |s|
        expect(s.to_float_if_number.is_a? Float).to eq false
        expect(s.to_float_if_number).to eq s
      end
    end
  end
end