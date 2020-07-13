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

class CrossQuestionValidation < ApplicationRecord

  cattr_accessor(:valid_rules) { [] }
  cattr_accessor(:rules_with_no_related_question) { [] }
  cattr_accessor(:rule_checkers) { {} }

  RULES_THAT_APPLY_EVEN_WHEN_RELATED_ANSWER_NIL = %w(present_implies_present const_implies_present set_implies_present blank_unless_present)
  RULES_THAT_APPLY_EVEN_WHEN_ANSWER_NIL = %w(present_if_const)

  SAFE_OPERATORS = %w(== <= >= < > !=)
  SAFE_TEXT_OPERATORS = %w(== !=)
  ALLOWED_SET_OPERATORS = %w(included excluded range)
  ALLOWED_SET_TEXT_OPERATORS = %w(included excluded)

  belongs_to :question
  belongs_to :related_question, class_name: 'Question'

  validates_inclusion_of :rule, in: valid_rules
  validates_inclusion_of :operator, in: SAFE_OPERATORS, allow_blank: true

  validates_presence_of :question_id
  validate :one_of_related_question_or_list_of_questions
  validate { |cqv| SpecialRules.additional_cqv_validation(cqv) }
  validates_presence_of :rule
  validates_presence_of :error_message
  validates_length_of :error_message, maximum: 500

  validate do |cqv|
    # return true/false if it passed/failed 
    if cqv.rule == 'comparison'
      cqv.errors[:base] << "#{cqv.operator} not included in #{SAFE_OPERATORS.inspect}" unless SAFE_OPERATORS.include?(cqv.operator)
      cqv.errors[:base] << "invalid cqv offset \"#{cqv.constant}\" - constant offset must be an integer or decimal"  if cqv.constant.is_a?(String) && !(cqv.constant.is_number? || cqv.constant.empty?)
    end
  end

  before_save :downcase_constants_and_sets

  serialize :related_question_ids, Array
  serialize :set, Array
  serialize :conditional_set, Array


  def one_of_related_question_or_list_of_questions
    return if rules_with_no_related_question.include?(rule)
    unless [related_question_id, related_question_ids].count(&:present?) == 1
      errors[:base] << "invalid cqv - exactly one of related question or list of related questions must be supplied - " +
          "#{related_question_id.inspect},#{related_question_ids.inspect}"
    end
  end

  def self.register_checker(rule, block)
    # Call register_checker with the rule 'code' of your check.
    # Supply a block that takes the answer and related_answer
    # and returns whether true if the answer meets the rule's criteria
    # The supplied block can assume that no garbage data is stored
    # i.e. that raw_answer is not populated for either answer or related_answer
    rule_checkers[rule] = block
    valid_rules << rule
  end

  SpecialRules.register_additional_rules

  def self.check(answer, survey_configuration=nil)
    cqvs = answer.question.cross_question_validations
    warnings = cqvs.map do |cqv|
      cqv.check(answer,survey_configuration)
    end
    warnings.compact
  end

  def check(answer, survey_configuration)
    checker_params = {operator: operator, constant: constant,
                      set_operator: set_operator, set: set,
                      conditional_operator: conditional_operator, conditional_constant: conditional_constant,
                      conditional_set_operator: conditional_set_operator, conditional_set: conditional_set,
                      related_question_ids: related_question_ids}


    # don't bother checking if the question is unanswered or has an invalid answer
    return nil if CrossQuestionValidation.unanswered?(answer) && !RULES_THAT_APPLY_EVEN_WHEN_ANSWER_NIL.include?(rule) && !SpecialRules::RULES_THAT_APPLY_EVEN_WHEN_ANSWER_NIL.include?(rule)

    # we have to filter the answers on the response rather than using find, as we want to check through as-yet unsaved answers as part of batch processing
    related_answer = answer.response.get_answer_to(related_question_id) if related_question_id

    # most rules are not run unless the related question has been answered, so unless this is a special rule that runs
    # regardless, first check if a related question is relevant, then check if its answered
    return nil if related_question_id && skip_when_related_unanswered?(rule) && CrossQuestionValidation.unanswered?(related_answer)

    # now actually execute the rule
    if rule_checkers[rule].arity == 3
      error_message unless rule_checkers[rule].call answer, related_answer, checker_params
    else
      error_message unless rule_checkers[rule].call answer, related_answer, checker_params, survey_configuration
    end
  end

  private

  def downcase_constants_and_sets
    # Constants and sets are nil unless a value was supplied in the CQV
    # Constants sometimes come in as ints/floats rather than strings, so need to check if string first
    constant.downcase! if constant.is_a?(String) && !constant.nil?
    conditional_constant.downcase! if conditional_constant.is_a?(String) && !conditional_constant.nil?
    set.downcase! unless set.nil?
    conditional_set.downcase! unless conditional_set.nil?
  end

  def skip_when_related_unanswered?(rule)
    !RULES_THAT_APPLY_EVEN_WHEN_RELATED_ANSWER_NIL.include?(rule)
  end

  def self.unanswered?(answer)
    answer.nil? || answer.answer_value.nil? || answer.raw_answer
  end

  def self.answered?(answer)
    # true for non-raw answers only
    answer && !answer.answer_value.nil? && !answer.raw_answer
  end

  def self.is_operator_safe?(operator, is_textual_operator=false)
    # Valid operator set is different if the operator is being applied to a String
    if is_textual_operator
      SAFE_TEXT_OPERATORS.include? operator
    else
      SAFE_OPERATORS.include? operator
    end
  end

  def self.is_set_operator_valid?(set_operator, set_has_textual_element=false)
    # Valid operator set is different if the set contains a String element
    if set_has_textual_element
      ALLOWED_SET_TEXT_OPERATORS.include? set_operator
    else
      ALLOWED_SET_OPERATORS.include? set_operator
    end
  end

  def self.set_meets_condition?(set, set_operator, value)
    return false unless set.is_a?(Array) && value.present?
    if set.contains_non_numerical_string? || (value.is_a?(String) && !value.is_number?)
      return false unless is_set_operator_valid?(set_operator, true)
    else
      return false unless is_set_operator_valid?(set_operator, false)
    end

    case set_operator
      when 'included'
        return set.include?(value)
      when 'excluded'
        return (!set.include?(value))
      when 'range' # inclusive
        return (value >= set.first && value <= set.last)
      else
        return false
    end
  end

  def self.const_meets_condition?(lhs, operator, rhs)
    if lhs.is_a?(String) && rhs.is_a?(String)
      return lhs.send operator, rhs if is_operator_safe? operator, true
    else
      return lhs.send operator, rhs if is_operator_safe? operator, false
    end
    return false
  end

  def self.aggregate_date_time(d, t)
    Time.utc(d.year, d.month, d.day, t.hour, t.min)
  end

  def self.sanitise_offset(checker_params)
    checker_params[:constant].blank? ? 0 : checker_params[:constant]
  end

  def self.sanitise_constant(constant)
    if constant.is_a?(String) && constant.is_number?
      constant.to_f
    else
      constant
    end
  end

  register_checker 'comparison', lambda { |answer, related_answer, checker_params|
    offset = sanitise_offset(checker_params).to_f # Always cast offset to float, since there is no logical way to offset by text
    const_meets_condition?(answer.comparable_answer, checker_params[:operator], related_answer.answer_with_offset(offset))
  }

  register_checker 'present_implies_constant', lambda { |answer, related_answer, checker_params|
    # e.g. If StartCPAPDate is a date, CPAPhrs must be greater than 0 (answer = CPAPhrs, related = StartCPAPDate)
    # return if related is not present (i.e. not answered or not answered correctly)
    const_meets_condition?(answer.comparable_answer, checker_params[:operator], sanitise_constant(checker_params[:constant]))
  }

  register_checker 'const_implies_const', lambda { |answer, related_answer, checker_params|
    break true unless const_meets_condition?(related_answer.comparable_answer, checker_params[:conditional_operator], sanitise_constant(checker_params[:conditional_constant]))
    const_meets_condition?(answer.comparable_answer, checker_params[:operator], sanitise_constant(checker_params[:constant]))
  }

  register_checker 'const_implies_set', lambda { |answer, related_answer, checker_params|
    break true unless const_meets_condition?(related_answer.comparable_answer, checker_params[:conditional_operator], sanitise_constant(checker_params[:conditional_constant]))
    set_meets_condition?(checker_params[:set], checker_params[:set_operator], answer.comparable_answer)
  }

  register_checker 'set_implies_set', lambda { |answer, related_answer, checker_params|
    break true unless set_meets_condition?(checker_params[:conditional_set], checker_params[:conditional_set_operator], related_answer.comparable_answer)
    set_meets_condition?(checker_params[:set], checker_params[:set_operator], answer.comparable_answer)
  }

  register_checker 'blank_if_const', lambda { |answer, related_answer, checker_params|
    # E.g. If Died_ is 0, DiedDate must be blank (rule on DiedDate)
    related_meets_condition = const_meets_condition?(related_answer.comparable_answer, checker_params[:conditional_operator], sanitise_constant(checker_params[:conditional_constant]))
    break true unless related_meets_condition
    # now fail if answer is present, but  answer must be present if we got this far, so just fail
    false
  }

  register_checker 'present_if_const', lambda { |answer, related_answer, checker_params|
    # E.g. If Gest < 32, LastO2 must be present
    related_meets_condition = const_meets_condition?(related_answer.comparable_answer, checker_params[:conditional_operator], sanitise_constant(checker_params[:conditional_constant]))
    break true unless related_meets_condition
    # check if answer is answered
    answered?(answer)
  }

  # runs even when related is not answered
  register_checker 'blank_unless_present', lambda { |answer, related_answer, checker_params|
    # E.g. Infection_Type2 must be blank unless Infection_Type1 is present (rule on Infection_Type2)
    # Inf2 is definitely answered, so fail if Inf1 is not answered

    # Note this is NOT the same as answered?(related_answer)
    related_answer.present? && related_answer.answer_value.present?
  }

  # TODO: test me
  # This rule is a 'comparison' comparing this answer with the difference (in hours) between two pairs of date/times.
  register_checker 'multi_hours_date_to_date', lambda { |answer, unused_related_answer, checker_params|
    related_ids = checker_params[:related_question_ids]
    date1 = answer.response.get_answer_to(related_ids[0])
    time1 = answer.response.get_answer_to(related_ids[1])
    date2 = answer.response.get_answer_to(related_ids[2])
    time2 = answer.response.get_answer_to(related_ids[3])

    break true if [date1, time1, date2, time2].any? { |related_answer| unanswered?(related_answer) }

    offset = sanitise_offset(checker_params).to_f # Always cast offset to float, since there is no logical way to offset by text

    datetime1 = aggregate_date_time(date1.answer_value, time1.answer_value)
    datetime2 = aggregate_date_time(date2.answer_value, time2.answer_value)

    hour_difference = (datetime2 - datetime1).abs / 1.hour
    hour_difference = hour_difference.round
    const_meets_condition?(answer.answer_value, checker_params[:operator], hour_difference + offset)
  }

  # TODO: test me
  # This rule is a 'comparison' for two pairs of date/times. This rule should be applied to both the date and the time questions.
  register_checker 'multi_compare_datetime_quad', lambda { |answer, unused_related_answer, checker_params|
    related_ids = checker_params[:related_question_ids]
    date1 = answer.response.get_answer_to(related_ids[0])
    time1 = answer.response.get_answer_to(related_ids[1])
    date2 = answer.response.get_answer_to(related_ids[2])
    time2 = answer.response.get_answer_to(related_ids[3])

    break true if [date1, time1, date2, time2].any? { |answer| unanswered?(answer) }

    datetime1 = aggregate_date_time(date1.answer_value, time1.answer_value)
    datetime2 = aggregate_date_time(date2.answer_value, time2.answer_value)

    offset = sanitise_offset(checker_params).to_f # Always cast offset to float, since there is no logical way to offset by text

    const_meets_condition?(datetime1, checker_params[:operator], datetime2 + offset)
  }

  # runs even when related is not answered
  register_checker 'present_implies_present', lambda { |answer, related_answer, checker_params|
    answered?(related_answer)
  }

  # runs even when related is not answered
  register_checker 'const_implies_present', lambda { |answer, related_answer, checker_params|
    break true unless const_meets_condition?(answer.comparable_answer, checker_params[:operator], sanitise_constant(checker_params[:constant]))
    # we know the answer meets the criteria, so now just check if related has been answered
    answered?(related_answer)
  }

  # runs even when related is not answered
  register_checker 'set_implies_present', lambda { |answer, related_answer, checker_params|
    break true unless set_meets_condition?(checker_params[:set], checker_params[:set_operator], answer.comparable_answer)
    # we know the answer meets the criteria, so now just check if related has been answered
    answered?(related_answer)
  }

  register_checker 'set_present_implies_present', lambda { |answer, unused_related_answer, checker_params|
    # e.g If IVH is 1-4 and USd6wk is a date, Cysts must be between 0 and 4 [which really means cysts must be answered]
    # rule on IVH, related are Usd6wk and Cysts
    related_ids = checker_params[:related_question_ids]
    date = answer.response.get_answer_to(related_ids[0])
    required_answer = answer.response.get_answer_to(related_ids[1])

    #Conditions (IF)
    break true unless set_meets_condition?(checker_params[:set], checker_params[:set_operator], answer.comparable_answer)
    break true unless answered?(date)

    #Requirements (THEN)
    answered?(required_answer)
  }

  register_checker 'const_implies_one_of_const', lambda { |answer, related_answer, checker_params|
    break true unless const_meets_condition?(answer.comparable_answer, checker_params[:operator], sanitise_constant(checker_params[:constant]))
    # we know the answer meets the criteria, so now check if any of the related ones have the correct value
    results = checker_params[:related_question_ids].collect do |question_id|
      related_answer = answer.response.get_answer_to(question_id)
      if answered?(related_answer)
        const_meets_condition?(related_answer.comparable_answer, checker_params[:conditional_operator], sanitise_constant(checker_params[:conditional_constant]))
      else
        false
      end
    end
    results.include?(true)
  }

end
