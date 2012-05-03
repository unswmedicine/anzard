require 'spec_helper'

describe CrossQuestionValidation do
  describe "Associations" do
    it { should belong_to :question }
    it { should belong_to :related_question }
  end
  describe "Validations" do
    it { should validate_presence_of :question_id }
    it { should validate_presence_of :rule }
    it { should validate_presence_of :error_message }
    it "should validate that the rule is one of the allowed rules" do
      CrossQuestionValidation::VALID_RULES.each do |value|
        should allow_value(value).for(:rule)
      end
      Factory.build(:cross_question_validation, rule: 'Blahblah').should_not be_valid
    end
    it "should validate only one of related question, related question list, multiple rule list is populated" do
      # 0 0 0 F
      # 0 0 1 T
      # 0 1 0 T
      # 0 1 1 F
      # 1 0 0 T
      # 1 0 1 F
      # 1 1 0 F
      # 1 1 1 F

      Factory.build(:cross_question_validation, related_question_id: nil, related_question_ids: nil, related_rule_ids: nil).should_not be_valid
      Factory.build(:cross_question_validation, related_question_id: nil, related_question_ids: nil, related_rule_ids: [1]).should be_valid
      Factory.build(:cross_question_validation, related_question_id: nil, related_question_ids: [1], related_rule_ids: nil).should be_valid
      Factory.build(:cross_question_validation, related_question_id: nil, related_question_ids: [1], related_rule_ids: [1]).should_not be_valid
      Factory.build(:cross_question_validation, related_question_id: 1, related_question_ids: nil, related_rule_ids: nil).should be_valid
      Factory.build(:cross_question_validation, related_question_id: 1, related_question_ids: nil, related_rule_ids: [1]).should_not be_valid
      Factory.build(:cross_question_validation, related_question_id: 1, related_question_ids: [1], related_rule_ids: nil).should_not be_valid
      Factory.build(:cross_question_validation, related_question_id: 1, related_question_ids: [1], related_rule_ids: [1]).should_not be_valid

    end
  end

  describe "helpers" do
    ALL_OPERATORS = %w(* / + - % ** == != > < >= <= <=> === eql? equal? = += -+ *= /+ %= **= & | ^ ~ << >> and or && || ! not ?: .. ...)
    UNSAFE_OPERATORS = ALL_OPERATORS - CrossQuestionValidation::SAFE_OPERATORS
    describe 'safe operators' do

      it "should accept 'safe' operators" do
        CrossQuestionValidation::SAFE_OPERATORS.each do |op|
          CrossQuestionValidation.is_operator_safe?(op).should eq true
        end
      end
      it "should reject 'unsafe' operators" do
        UNSAFE_OPERATORS.each do |op|
          CrossQuestionValidation.is_operator_safe?(op).should eq false
        end
      end
    end

    describe 'valid set operators' do

      it "should accept valid operators" do
        CrossQuestionValidation::ALLOWED_SET_OPERATORS.each do |op|
          CrossQuestionValidation.is_set_operator_valid?(op).should eq true
        end
      end
      it "should reject invalid operators" do
        CrossQuestionValidation.is_set_operator_valid?("invalid_operator").should eq false
        CrossQuestionValidation.is_set_operator_valid?("something_else").should eq false

      end
    end

    describe 'set_meets_conditions' do
      it "should pass true statements" do
        CrossQuestionValidation.set_meets_condition?([1, 3, 5, 7], "included", 5).should eq true
        CrossQuestionValidation.set_meets_condition?([1, 3, 5, 7], "excluded", 4).should eq true
        CrossQuestionValidation.set_meets_condition?([1, 5], "range", 4).should eq true
        CrossQuestionValidation.set_meets_condition?([1, 5], "range", 1).should eq true
        CrossQuestionValidation.set_meets_condition?([1, 5], "range", 5).should eq true
        CrossQuestionValidation.set_meets_condition?([1, 5], "range", 4.9).should eq true
        CrossQuestionValidation.set_meets_condition?([1, 5], "between", 1.1).should eq true
        CrossQuestionValidation.set_meets_condition?([1, 5], "between", 2).should eq true
        CrossQuestionValidation.set_meets_condition?([1, 5], "between", 4).should eq true
        CrossQuestionValidation.set_meets_condition?([1, 5], "between", 4.9).should eq true
      end

      it "should reject false statements" do
        CrossQuestionValidation.set_meets_condition?([1, 3, 5, 7], "included", 4).should eq false
        CrossQuestionValidation.set_meets_condition?([1, 3, 5, 7], "excluded", 5).should eq false
        CrossQuestionValidation.set_meets_condition?([1, 5], "range", 0).should eq false
        CrossQuestionValidation.set_meets_condition?([1, 5], "range", 6).should eq false
        CrossQuestionValidation.set_meets_condition?([1, 5], "range", 5.1).should eq false
        CrossQuestionValidation.set_meets_condition?([1, 5], "between", 0).should eq false
        CrossQuestionValidation.set_meets_condition?([1, 5], "between", 6).should eq false
        CrossQuestionValidation.set_meets_condition?([1, 5], "between", 1).should eq false
        CrossQuestionValidation.set_meets_condition?([1, 5], "between", 5).should eq false
      end

      it "should reject statements with invalid operators" do
        CrossQuestionValidation.set_meets_condition?([1, 3, 5], "swirly", 0).should eq false
        CrossQuestionValidation.set_meets_condition?([1, 3, 5], "includified", 0).should eq false
      end
    end

    describe 'const_meets_conditions' do
      it "should pass true statements" do
        CrossQuestionValidation.const_meets_condition?(0, "==", 0).should eq true
        CrossQuestionValidation.const_meets_condition?(5, "!=", 3).should eq true
        CrossQuestionValidation.const_meets_condition?(5, ">=", 3).should eq true
        CrossQuestionValidation.const_meets_condition?(5, "==", 3, 2).should eq true
      end

      it "should reject false statements" do
        CrossQuestionValidation.const_meets_condition?(0, "<", 0).should eq false
        CrossQuestionValidation.const_meets_condition?(5, "==", 3).should eq false
        CrossQuestionValidation.const_meets_condition?(5, "<=", 3).should eq false
        CrossQuestionValidation.const_meets_condition?(5, "==", 5, 2).should eq false
      end

      it "should reject statements with unsafe operators" do
        CrossQuestionValidation.const_meets_condition?(0, UNSAFE_OPERATORS.first, 0).should eq false
        CrossQuestionValidation.const_meets_condition?(0, UNSAFE_OPERATORS.last, 0).should eq false
      end
    end
  end

  describe "primary?" do
    it "should return primary for standard validations" do

    end
    it "should return primary for rules with related rules" do

    end
    it "should return false for "
  end

  describe "check" do
    before :each do
      @survey = Factory :survey
      @section = Factory :section, survey: @survey
    end

    def do_cqv_check (first, val)
      error_messages = CrossQuestionValidation.check first
      error_messages.should eq val
    end

    def build_two_answers(val_first, val_second)
      first = Factory :answer, response: @response, question: @q1, answer_value: val_first
      second = Factory :answer, response: @response, question: @q2, answer_value: val_second
      return first, second
    end

    def standard_cqv_test(val_first, val_second, error)
      first, second = build_two_answers(val_first, val_second)
      do_cqv_check(first, error)
    end

    describe "implications" do
      before :each do
        @response = Factory :response, survey: @survey
      end
      describe 'date implies constant' do
        before :each do
          @error_message = 'q2 was date, q1 was not expected constant (-1)'
          @q1 = Factory :question, section: @section, question_type: 'Integer'
          @q2 = Factory :question, section: @section, question_type: 'Date'
          Factory :cqv_date_implies_constant, question: @q1, related_question: @q2, error_message: @error_message, operator: '==', constant: -1
        end
        it "handles nils" do
          standard_cqv_test({}, {}, [])
        end
        it "doesn't reject the LHS when RHS not a date" do
          standard_cqv_test({}, "5", [])
        end
        it "rejects when RHS is date and LHS is not expected constant" do
          standard_cqv_test(5, Date.new(2012, 2, 3), [@error_message])
        end
        it "accepts when RHS is date and LHS is expected constant" do
          standard_cqv_test(-1, Date.new(2012, 2, 1), [])
        end
      end

      describe 'constant implies constant' do
        before :each do
          @error_message = 'q2 was != 0, q1 was not > 0'
          @q1 = Factory :question, section: @section, question_type: 'Integer'
          @q2 = Factory :question, section: @section, question_type: 'Integer'
          Factory :cqv_const_implies_const, question: @q1, related_question: @q2, error_message: @error_message
          #conditional_operator "!="
          #conditional_constant 0
          #operator ">"
          #constant 0
        end
        it "handles nils" do
          standard_cqv_test({}, {}, [])
        end
        it "doesn't reject the LHS when RHS not expected constant" do
          standard_cqv_test(-1, 0, [])
        end
        it "rejects when RHS is specified constant and LHS is not expected constant" do
          standard_cqv_test(-1, 1, [@error_message])
        end
        it "accepts when RHS is specified constant and LHS is expected constant" do
          standard_cqv_test(1, 1, [])
        end
      end

      describe 'constant implies set' do
        before :each do
          @error_message = 'q2 was != 0, q1 was not in specified set [1,3,5,7]'
          @q1 = Factory :question, section: @section, question_type: 'Integer'
          @q2 = Factory :question, section: @section, question_type: 'Integer'
          Factory :cqv_const_implies_set, question: @q1, related_question: @q2, error_message: @error_message
          #conditional_operator "!="
          #conditional_constant 0
          #set_operator "included"
          #set [1,3,5,7]
        end
        it "handles nils" do
          standard_cqv_test({}, {}, [])
        end
        it "doesn't reject the LHS when RHS not expected constant" do
          standard_cqv_test(-1, 0, [])
        end
        it "rejects when RHS is specified const and LHS is not in expected set" do
          standard_cqv_test(0, 1, [@error_message])
        end
        it "accepts when RHS is specified const and LHS is in expected set" do
          standard_cqv_test(1, 1, [])
        end
      end

      describe 'set implies const' do
        before :each do
          @error_message = 'q2 was in [2,4,6,8], q1 must be > 0'
          @q1 = Factory :question, section: @section, question_type: 'Integer'
          @q2 = Factory :question, section: @section, question_type: 'Integer'
          Factory :cqv_set_implies_const, question: @q1, related_question: @q2, error_message: @error_message
          #conditional_set_operator "included"
          #conditional_set [2,4,6,8]
          #operator ">"
          #constant 0
        end
        it "handles nils" do
          standard_cqv_test({}, {}, [])
        end
        it "doesn't reject the LHS when RHS not in expected set" do
          standard_cqv_test(-1, 0, [])
        end
        it "rejects when RHS is in specified set and LHS is not expected constant" do
          standard_cqv_test(0, 2, [@error_message])
        end
        it "accepts when RHS is in specified set and LHS is expected constant" do
          standard_cqv_test(1, 2, [])
        end
      end

      describe 'set implies set' do
        before :each do
          @error_message = 'q2  was in [2,4,6,8], q1 was not in specified set [1,3,5,7]'
          @q1 = Factory :question, section: @section, question_type: 'Integer'
          @q2 = Factory :question, section: @section, question_type: 'Integer'
          Factory :cqv_set_implies_set, question: @q1, related_question: @q2, error_message: @error_message
          #conditional_set_operator "included"
          #conditional_set [2,4,6,8]
          #set_operator "included"
          #set [1,3,5,7]
        end
        it "handles nils" do
          standard_cqv_test({}, {}, [])
        end
        it "doesn't reject the LHS when RHS not in expected set" do
          standard_cqv_test(-1, 0, [])
        end
        it "rejects when RHS is in specified set and LHS is in expected set" do
          standard_cqv_test(0, 2, [@error_message])
        end
        it "accepts when RHS is in specified set and LHS is in expected set" do
          standard_cqv_test(1, 2, [])
        end
      end

    end

    describe "Blank Unless " do
      before :each do
        @response = Factory :response, survey: @survey
      end

      describe 'blank unless Qx = N' do
        before :each do
          @error_message = 'q2 was != -1, q1 must be blank'
          @q1 = Factory :question, section: @section, question_type: 'Integer'
          @q2 = Factory :question, section: @section, question_type: 'Integer'
          Factory :cqv_blank_unless_const, question: @q1, related_question: @q2, error_message: @error_message
          #conditional_operator "=="
          #conditional_constant -1
        end
        it "handles nils" do
          standard_cqv_test({}, {}, [])
        end
        it "doesn't reject a non-blank LHS when RHS meets requirements" do
          standard_cqv_test("12345", -1, [])
        end
        it "rejects when RHS isn't expected value and LHS isn't blank" do
          standard_cqv_test("12345", 0, [@error_message])
        end
        it "rejects when RHS is blank value and LHS isn't blank" do
          standard_cqv_test("12345", {}, [@error_message])
        end
      end

      describe 'blank unless Qx is within range N..M (inclusive)' do
        before :each do
          @error_message = 'q2 was outside 0..99 (inclusive), q1 must be blank'
          @q1 = Factory :question, section: @section, question_type: 'Integer'
          @q2 = Factory :question, section: @section, question_type: 'Decimal'
          Factory :cqv_blank_unless_set, question: @q1, related_question: @q2, error_message: @error_message
          #conditional_set_operator "range"
          #conditional_set [0,99]
        end
        it "handles nils" do
          standard_cqv_test({}, {}, [])
        end
        it "doesn't reject the LHS when RHS expected" do
          standard_cqv_test(-1, 0, [])
        end
        it "rejects when RHS isn't expected value (lower) and LHS isn't blank" do
          standard_cqv_test(-1, -1, [@error_message])
        end
        it "rejects when RHS isn't expected value (higher) and LHS isn't blank" do
          standard_cqv_test(-1, 100, [@error_message])
        end
        it "rejects when RHS is blank value and LHS isn't blank" do
          standard_cqv_test(-1, {}, [@error_message])
        end
      end

      describe 'blank unless Qx is between N annd M' do
        before :each do
          @error_message = 'q2 was not between 0...99 (exclusive), q1 must be blank'
          @q1 = Factory :question, section: @section, question_type: 'Integer'
          @q2 = Factory :question, section: @section, question_type: 'Decimal'
          Factory :cqv_blank_unless_set, question: @q1, related_question: @q2, error_message: @error_message, conditional_set_operator: "between"
          #conditional_set [0,99]
        end
        it "handles nils" do
          standard_cqv_test({}, {}, [])
        end
        it "doesn't reject the LHS when RHS expected" do
          standard_cqv_test(-1, 1, [])
        end
        it "rejects when RHS isn't expected value (lower) and LHS isn't blank" do
          standard_cqv_test(-1, 0, [@error_message])
        end
        it "rejects when RHS isn't expected value (higher) and LHS isn't blank" do
          standard_cqv_test(-1, 99, [@error_message])
        end
        it "rejects when RHS is blank value and LHS isn't blank" do
          standard_cqv_test(-1, {}, [@error_message])
        end
      end

    end

    describe "comparisons (using dates to represent a complex type that supports <,>,== etc)" do
      before :each do
        @q1 = Factory :question, section: @section, question_type: 'Date'
        @q2 = Factory :question, section: @section, question_type: 'Date'
        @response = Factory :response, survey: @survey
      end
      describe "date_lte" do
        before :each do
          @error_message = 'not lte'
          Factory :cross_question_validation, rule: 'comparison', operator: '<=', question: @q1, related_question: @q2, error_message: @error_message
        end
        it "handles nils" do
          standard_cqv_test({}, {}, [])
        end
        it "rejects gt" do
          standard_cqv_test(Date.new(2012, 2, 3), Date.new(2012, 2, 2), [@error_message])
        end
        it "accepts lt" do
          standard_cqv_test(Date.new(2012, 2, 1), Date.new(2012, 2, 2), [])
        end
        it "accepts eq" do
          standard_cqv_test(Date.new(2012, 2, 2), Date.new(2012, 2, 2), [])
        end
      end
      describe "date_gte" do
        before :each do
          @error_message = 'not gte'
          Factory :cross_question_validation, rule: 'comparison', operator: '>=', question: @q1, related_question: @q2, error_message: @error_message
        end
        it "handles nils" do
          standard_cqv_test({}, {}, [])
        end
        it "accepts gt" do
          standard_cqv_test(Date.new(2012, 2, 3), Date.new(2012, 2, 2), [])
        end
        it "rejects lt" do
          standard_cqv_test(Date.new(2012, 2, 1), Date.new(2012, 2, 2), [@error_message])
        end
        it "accepts eq" do
          standard_cqv_test(Date.new(2012, 2, 2), Date.new(2012, 2, 2), [])
        end
      end
      describe "date_gt" do
        before :each do
          @error_message = 'not gt'
          Factory :cross_question_validation, rule: 'comparison', operator: '>', question: @q1, related_question: @q2, error_message: @error_message
        end
        it "handles nils" do
          standard_cqv_test({}, {}, [])
        end
        it "accepts gt" do
          standard_cqv_test(Date.new(2012, 2, 3), Date.new(2012, 2, 2), [])
        end
        it "rejects lt" do
          standard_cqv_test(Date.new(2012, 2, 1), Date.new(2012, 2, 2), [@error_message])
        end
        it "rejects eq" do
          standard_cqv_test(Date.new(2012, 2, 2), Date.new(2012, 2, 2), [@error_message])
        end
      end
      describe "date_lt" do
        before :each do
          @error_message = 'not lt'
          Factory :cross_question_validation, rule: 'comparison', operator: '<', question: @q1, related_question: @q2, error_message: @error_message
        end
        it "handles nils" do
          standard_cqv_test({}, {}, [])
        end
        it "rejects gt" do
          standard_cqv_test(Date.new(2012, 2, 3), Date.new(2012, 2, 2), [@error_message])
        end
        it "accepts lt" do
          standard_cqv_test(Date.new(2012, 2, 1), Date.new(2012, 2, 2), [])
        end
        it "rejects eq" do
          standard_cqv_test(Date.new(2012, 2, 2), Date.new(2012, 2, 2), [@error_message])
        end
      end
      describe "date_eq" do
        before :each do
          @error_message = 'not eq'
          Factory :cross_question_validation, rule: 'comparison', operator: '==', question: @q1, related_question: @q2, error_message: @error_message
        end
        it "handles nils" do
          standard_cqv_test({}, {}, [])
        end
        it "rejects gt" do
          standard_cqv_test(Date.new(2012, 2, 3), Date.new(2012, 2, 2), [@error_message])
        end
        it "rejects lt" do
          standard_cqv_test(Date.new(2012, 2, 1), Date.new(2012, 2, 2), [@error_message])
        end
        it "accepts eq" do
          standard_cqv_test(Date.new(2012, 2, 2), Date.new(2012, 2, 2), [])
        end
      end
      describe "date_ne" do
        before :each do
          @error_message = 'are eq'
          Factory :cross_question_validation, rule: 'comparison', operator: '!=', question: @q1, related_question: @q2, error_message: @error_message
        end
        it "handles nils" do
          standard_cqv_test({}, {}, [])
        end
        it "accepts gt" do
          standard_cqv_test(Date.new(2012, 2, 3), Date.new(2012, 2, 2), [])
        end
        it "accepts lt" do
          standard_cqv_test(Date.new(2012, 2, 1), Date.new(2012, 2, 2), [])
        end
        it "rejects eq" do
          standard_cqv_test(Date.new(2012, 2, 2), Date.new(2012, 2, 2), [@error_message])
        end
      end
      describe "comparisons with offsets function normally" do
        #This isn't much to test here: We're utilising the other class' ability to use +/-, so as long
        # As it works for one case involving a 'complex' type, that's good enough.
        before :each do
          @error_message = 'not eq'
        end
        it "accepts X eq Y (offset +1) when Y = X-1" do
          Factory :cross_question_validation, rule: 'comparison', operator: '==', question: @q1, related_question: @q2, error_message: @error_message, constant: 1
          standard_cqv_test(Date.new(2012, 2, 3), Date.new(2012, 2, 2), [])
        end
        it "rejects X eq Y (offset +1) when Y = X" do
          Factory :cross_question_validation, rule: 'comparison', operator: '==', question: @q1, related_question: @q2, error_message: @error_message, constant: 1
          standard_cqv_test(Date.new(2012, 2, 1), Date.new(2012, 2, 1), [@error_message])
        end
        it "accepts X eq Y (offset -1) when Y = X+1" do
          Factory :cross_question_validation, rule: 'comparison', operator: '==', question: @q1, related_question: @q2, error_message: @error_message, constant: -1
          standard_cqv_test(Date.new(2012, 2, 3), Date.new(2012, 2, 4), [])
        end
        it "rejects X eq Y (offset -1) when Y = X" do
          Factory :cross_question_validation, rule: 'comparison', operator: '==', question: @q1, related_question: @q2, error_message: @error_message, constant: -1
          standard_cqv_test(Date.new(2012, 2, 1), Date.new(2012, 2, 1), [@error_message])
        end
      end
    end
  end
end
