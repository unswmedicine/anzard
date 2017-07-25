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
end