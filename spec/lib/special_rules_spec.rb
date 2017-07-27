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

describe 'Special Rules' do

  describe 'RULE: special_rule_comp1' do
    # special_rule_comp1: n_v_egth + n_s_egth + n_eggs + n_recvd >= n_donate + n_ivf + n_icsi + n_egfz_s + n_egfz_v
    before(:each) do
      @survey = create(:survey)
      @section = create(:section, survey: @survey)
      @n_v_egth = create(:question, code: 'N_V_EGTH', section: @section, question_type: Question::TYPE_INTEGER)
      @n_s_egth = create(:question, code: 'N_S_EGTH', section: @section, question_type: Question::TYPE_INTEGER)
      @n_eggs = create(:question, code: 'N_EGGS', section: @section, question_type: Question::TYPE_INTEGER)
      @n_recvd = create(:question, code: 'N_RECVD', section: @section, question_type: Question::TYPE_INTEGER)
      @n_donate = create(:question, code: 'N_DONATE', section: @section, question_type: Question::TYPE_INTEGER)
      @n_ivf = create(:question, code: 'N_IVF', section: @section, question_type: Question::TYPE_INTEGER)
      @n_icsi = create(:question, code: 'N_ICSI', section: @section, question_type: Question::TYPE_INTEGER)
      @n_egfz_s = create(:question, code: 'N_EGFZ_S', section: @section, question_type: Question::TYPE_INTEGER)
      @n_egfz_v = create(:question, code: 'N_EGFZ_V', section: @section, question_type: Question::TYPE_INTEGER)
      @cqv = create(:cross_question_validation, rule: 'special_rule_comp1', question: @n_v_egth, error_message: 'My error message', related_question_id: nil)
      @response = create(:response, survey: @survey)
    end

    it 'should raise an error if used on the wrong question' do
      q = create(:question, code: 'Blah')
      cqv = build(:cross_question_validation, rule: 'special_rule_comp1', question: q)
      expect(cqv.valid?).to be false
      expect(cqv.errors[:base]).to eq ['special_rule_comp1 requires question code N_V_EGTH but got Blah']
    end

    it 'should apply even when N_V_EGTH is not answered' do
      expect(SpecialRules::RULES_THAT_APPLY_EVEN_WHEN_ANSWER_NIL).to include('special_rule_comp1')
    end

    it 'should pass when no questions are answered' do
      answer = create(:answer, question: @n_v_egth, answer_value: nil, response: @response)
      answer.reload
      expect(@cqv.check(answer)).to be_nil
    end

    describe 'when only one question is answered' do
      it 'should pass when N_V_EGTH is the only question answered' do
        answer = create(:answer, question: @n_v_egth, answer_value: 0, response: @response)
        answer.reload
        expect(@cqv.check(answer)).to be_nil
      end

      describe 'when N_V_EGTH is unanswered' do
        before :each do
          @answer = create(:answer, question: @n_v_egth, answer_value: nil, response: @response)
          @answer.reload
        end

        it 'should pass when only N_S_EGTH is answered' do
          create(:answer, question: @n_s_egth, answer_value: 0, response: @response)
          @answer.reload
          expect(@cqv.check(@answer)).to be_nil
        end

        it 'should pass when only N_EGGS is answered' do
          create(:answer, question: @n_eggs, answer_value: 0, response: @response)
          @answer.reload
          expect(@cqv.check(@answer)).to be_nil
        end

        it 'should pass when only N_RECVD is answered' do
          create(:answer, question: @n_recvd, answer_value: 0, response: @response)
          @answer.reload
          expect(@cqv.check(@answer)).to be_nil
        end

        it 'should pass when only N_DONATE is answered' do
          create(:answer, question: @n_donate, answer_value: 0, response: @response)
          @answer.reload
          expect(@cqv.check(@answer)).to be_nil
        end

        it 'should pass when only N_IVF is answered' do
          create(:answer, question: @n_ivf, answer_value: 0, response: @response)
          @answer.reload
          expect(@cqv.check(@answer)).to be_nil
        end

        it 'should pass when only N_ICSI is answered' do
          create(:answer, question: @n_icsi, answer_value: 0, response: @response)
          @answer.reload
          expect(@cqv.check(@answer)).to be_nil
        end

        it 'should pass when only N_EGFZ_S is answered' do
          create(:answer, question: @n_egfz_s, answer_value: 0, response: @response)
          @answer.reload
          expect(@cqv.check(@answer)).to be_nil
        end

        it 'should pass when only N_EGFZ_V is answered' do
          create(:answer, question: @n_egfz_v, answer_value: 0, response: @response)
          @answer.reload
          expect(@cqv.check(@answer)).to be_nil
        end
      end
    end

    describe 'when all questions are answered' do
      it 'should pass when n_v_egth sum equal to n_donate sum' do
        answer = create(:answer, question: @n_v_egth, answer_value: 0, response: @response)
        create(:answer, question: @n_s_egth, answer_value: 0, response: @response)
        create(:answer, question: @n_eggs, answer_value: 0, response: @response)
        create(:answer, question: @n_recvd, answer_value: 0, response: @response)
        create(:answer, question: @n_donate, answer_value: 0, response: @response)
        create(:answer, question: @n_ivf, answer_value: 0, response: @response)
        create(:answer, question: @n_icsi, answer_value: 0, response: @response)
        create(:answer, question: @n_egfz_s, answer_value: 0, response: @response)
        create(:answer, question: @n_egfz_v, answer_value: 0, response: @response)
        answer.reload
        expect(@cqv.check(answer)).to be_nil
      end

      it 'should pass when n_v_egth sum greater than n_donate sum' do
        answer = create(:answer, question: @n_v_egth, answer_value: 1, response: @response)
        create(:answer, question: @n_s_egth, answer_value: 1, response: @response)
        create(:answer, question: @n_eggs, answer_value: 1, response: @response)
        create(:answer, question: @n_recvd, answer_value: 1, response: @response)
        create(:answer, question: @n_donate, answer_value: 0, response: @response)
        create(:answer, question: @n_ivf, answer_value: 0, response: @response)
        create(:answer, question: @n_icsi, answer_value: 0, response: @response)
        create(:answer, question: @n_egfz_s, answer_value: 0, response: @response)
        create(:answer, question: @n_egfz_v, answer_value: 0, response: @response)
        answer.reload
        expect(@cqv.check(answer)).to be_nil
      end

      it 'should fail when n_v_egth sum less than n_donate sum' do
        answer = create(:answer, question: @n_v_egth, answer_value: 0, response: @response)
        create(:answer, question: @n_s_egth, answer_value: 0, response: @response)
        create(:answer, question: @n_eggs, answer_value: 0, response: @response)
        create(:answer, question: @n_recvd, answer_value: 0, response: @response)
        create(:answer, question: @n_donate, answer_value: 1, response: @response)
        create(:answer, question: @n_ivf, answer_value: 1, response: @response)
        create(:answer, question: @n_icsi, answer_value: 1, response: @response)
        create(:answer, question: @n_egfz_s, answer_value: 1, response: @response)
        create(:answer, question: @n_egfz_v, answer_value: 1, response: @response)
        answer.reload
        expect(@cqv.check(answer)).to eq('My error message')
      end
    end
  end

  describe 'Rule: special_rule_comp2' do
    # special_rule_comp2: n_ivf + n_icsi >=n_fert
    # i.e. n_fert <= n_ivf + n_icsi
    before :each do
      @survey = create(:survey)
      @section = create(:section, survey: @survey)
      @n_fert = create(:question, code: 'N_FERT', section: @section, question_type: Question::TYPE_INTEGER)
      @n_ivf = create(:question, code: 'N_IVF', section: @section, question_type: Question::TYPE_INTEGER)
      @n_icsi = create(:question, code: 'N_ICSI', section: @section, question_type: Question::TYPE_INTEGER)
      @cqv = create(:cross_question_validation, rule: 'special_rule_comp2', question: @n_fert, error_message: 'My error message', related_question_id: nil)
      @response = create(:response, survey: @survey)
    end

    it 'should raise an error if used on the wrong question' do
      q = create(:question, code: 'Blah')
      cqv = build(:cross_question_validation, rule: 'special_rule_comp2', question: q)
      expect(cqv.valid?).to be false
      expect(cqv.errors[:base]).to eq ['special_rule_comp2 requires question code N_FERT but got Blah']
    end

    it 'should treat n_icsi as 0 if unanswered' do
      answer = create(:answer, question: @n_fert, answer_value: 0, response: @response)
      create(:answer, question: @n_ivf, answer_value: 0, response: @response)
      answer.reload
      expect(@cqv.check(answer)).to be_nil
    end

    it 'should treat n_ivf as 0 if unanswered' do
      answer = create(:answer, question: @n_fert, answer_value: 0, response: @response)
      create(:answer, question: @n_icsi, answer_value: 0, response: @response)
      answer.reload
      expect(@cqv.check(answer)).to be_nil
    end

    it 'should pass if n_fert < (n_ivf + n_icsi)' do
      answer = create(:answer, question: @n_fert, answer_value: 1, response: @response)
      create(:answer, question: @n_ivf, answer_value: 1, response: @response)
      create(:answer, question: @n_icsi, answer_value: 1, response: @response)
      answer.reload
      expect(@cqv.check(answer)).to be_nil
    end

    it 'should pass if n_fert == (n_ivf + n_icsi)' do
      answer = create(:answer, question: @n_fert, answer_value: 2, response: @response)
      create(:answer, question: @n_ivf, answer_value: 1, response: @response)
      create(:answer, question: @n_icsi, answer_value: 1, response: @response)
      answer.reload
      expect(@cqv.check(answer)).to be_nil
    end

    it 'should fail if n_fert > (n_ivf + n_icsi)' do
      answer = create(:answer, question: @n_fert, answer_value: 3, response: @response)
      create(:answer, question: @n_ivf, answer_value: 1, response: @response)
      create(:answer, question: @n_icsi, answer_value: 1, response: @response)
      answer.reload
      expect(@cqv.check(answer)).to eq('My error message')
    end
  end

  describe 'Rule: special_rule_comp3' do
    # special_rule_comp3: (n_s_clth + n_v_clth + n_s_blth + n_v_blth + n_fert + n_embrec) >= (n_bl_et + n_cl_et + n_clfz_s + n_clfz_v + n_blfz_s + n_blfz_v + n_embdisp)
    before(:each) do
      @survey = create(:survey)
      @section = create(:section, survey: @survey)
      @n_s_clth = create(:question, code: 'N_S_CLTH', section: @section, question_type: Question::TYPE_INTEGER)
      @n_v_clth = create(:question, code: 'N_V_CLTH', section: @section, question_type: Question::TYPE_INTEGER)
      @n_s_blth = create(:question, code: 'N_S_BLTH', section: @section, question_type: Question::TYPE_INTEGER)
      @n_v_blth = create(:question, code: 'N_V_BLTH', section: @section, question_type: Question::TYPE_INTEGER)
      @n_fert = create(:question, code: 'N_FERT', section: @section, question_type: Question::TYPE_INTEGER)
      @n_embrec = create(:question, code: 'N_EMBREC', section: @section, question_type: Question::TYPE_INTEGER)
      @n_bl_et = create(:question, code: 'N_BL_ET', section: @section, question_type: Question::TYPE_INTEGER)
      @n_cl_et = create(:question, code: 'N_CL_ET', section: @section, question_type: Question::TYPE_INTEGER)
      @n_clfz_s = create(:question, code: 'N_CLFZ_S', section: @section, question_type: Question::TYPE_INTEGER)
      @n_clfz_v = create(:question, code: 'N_CLFZ_V', section: @section, question_type: Question::TYPE_INTEGER)
      @n_blfz_s = create(:question, code: 'N_BLFZ_S', section: @section, question_type: Question::TYPE_INTEGER)
      @n_blfz_v = create(:question, code: 'N_BLFZ_V', section: @section, question_type: Question::TYPE_INTEGER)
      @n_embdisp = create(:question, code: 'N_EMBDISP', section: @section, question_type: Question::TYPE_INTEGER)
      @cqv = create(:cross_question_validation, rule: 'special_rule_comp3', question: @n_s_clth, error_message: 'My error message', related_question_id: nil)
      @response = create(:response, survey: @survey)
    end

    it 'should raise an error if used on the wrong question' do
      q = create(:question, code: 'Blah')
      cqv = build(:cross_question_validation, rule: 'special_rule_comp3', question: q)
      expect(cqv.valid?).to be false
      expect(cqv.errors[:base]).to eq ['special_rule_comp3 requires question code N_S_CLTH but got Blah']
    end

    it 'should apply even when N_S_CLTH is not answered' do
      expect(SpecialRules::RULES_THAT_APPLY_EVEN_WHEN_ANSWER_NIL).to include('special_rule_comp3')
    end

    it 'should pass when no questions are answered' do
      answer = create(:answer, question: @n_s_clth, answer_value: nil, response: @response)
      answer.reload
      expect(@cqv.check(answer)).to be_nil
    end

    describe 'when only one question is answered' do
      it 'should pass when only N_S_CLTH is answered' do
        answer = create(:answer, question: @n_s_clth, answer_value: 0, response: @response)
        answer.reload
        expect(@cqv.check(answer)).to be_nil
      end

      describe 'when N_S_CLTH is unanswered' do
        before :each do
          @answer = create(:answer, question: @n_s_clth, answer_value: nil, response: @response)
          @answer.reload
        end

        it 'should pass when only N_V_CLTH is answered' do
          create(:answer, question: @n_v_clth, answer_value: 0, response: @response)
          @answer.reload
          expect(@cqv.check(@answer)).to be_nil
        end

        it 'should pass when only N_S_BLTH is answered' do
          create(:answer, question: @n_s_blth, answer_value: 0, response: @response)
          @answer.reload
          expect(@cqv.check(@answer)).to be_nil
        end

        it 'should pass when only N_V_BLTH is answered' do
          create(:answer, question: @n_v_blth, answer_value: 0, response: @response)
          @answer.reload
          expect(@cqv.check(@answer)).to be_nil
        end

        it 'should pass when only N_FERT is answered' do
          create(:answer, question: @n_fert, answer_value: 0, response: @response)
          @answer.reload
          expect(@cqv.check(@answer)).to be_nil
        end

        it 'should pass when only N_EMBREC is answered' do
          create(:answer, question: @n_embrec, answer_value: 0, response: @response)
          @answer.reload
          expect(@cqv.check(@answer)).to be_nil
        end

        it 'should pass when only N_BL_ET answered' do
          create(:answer, question: @n_bl_et, answer_value: 0, response: @response)
          @answer.reload
          expect(@cqv.check(@answer)).to be_nil
        end

        it 'should pass when only N_CL_ET is answered' do
          create(:answer, question: @n_cl_et, answer_value: 0, response: @response)
          @answer.reload
          expect(@cqv.check(@answer)).to be_nil
        end

        it 'should pass when only N_CLFZ_S is answered' do
          create(:answer, question: @n_clfz_s, answer_value: 0, response: @response)
          @answer.reload
          expect(@cqv.check(@answer)).to be_nil
        end

        it 'should pass when only N_CLFZ_V is answered' do
          create(:answer, question: @n_clfz_v, answer_value: 0, response: @response)
          @answer.reload
          expect(@cqv.check(@answer)).to be_nil
        end

        it 'should pass when only N_BLFZ_S is answered' do
          create(:answer, question: @n_blfz_s, answer_value: 0, response: @response)
          @answer.reload
          expect(@cqv.check(@answer)).to be_nil
        end

        it 'should pass when only N_BLFZ_V is answered' do
          create(:answer, question: @n_blfz_v, answer_value: 0, response: @response)
          @answer.reload
          expect(@cqv.check(@answer)).to be_nil
        end

        it 'should pass when only N_EMBDISP is answered' do
          create(:answer, question: @n_embdisp, answer_value: 0, response: @response)
          @answer.reload
          expect(@cqv.check(@answer)).to be_nil
        end
      end
    end

    describe 'when all questions are answered' do
      it 'should pass when n_s_clth sum equal to n_bl_et sum' do
        # Sum left-side
        answer = create(:answer, question: @n_s_clth, answer_value: 0, response: @response)
        create(:answer, question: @n_v_clth, answer_value: 0, response: @response)
        create(:answer, question: @n_s_blth, answer_value: 0, response: @response)
        create(:answer, question: @n_v_blth, answer_value: 0, response: @response)
        create(:answer, question: @n_fert, answer_value: 0, response: @response)
        create(:answer, question: @n_embrec, answer_value: 0, response: @response)
        # Sum right-side
        create(:answer, question: @n_bl_et, answer_value: 0, response: @response)
        create(:answer, question: @n_cl_et, answer_value: 0, response: @response)
        create(:answer, question: @n_clfz_s, answer_value: 0, response: @response)
        create(:answer, question: @n_clfz_v, answer_value: 0, response: @response)
        create(:answer, question: @n_blfz_s, answer_value: 0, response: @response)
        create(:answer, question: @n_blfz_v, answer_value: 0, response: @response)
        create(:answer, question: @n_embdisp, answer_value: 0, response: @response)
        answer.reload
        expect(@cqv.check(answer)).to be_nil
      end

      it 'should pass when n_s_clth sum greater than n_bl_et sum' do
        answer = create(:answer, question: @n_s_clth, answer_value: 1, response: @response)
        create(:answer, question: @n_v_clth, answer_value: 1, response: @response)
        create(:answer, question: @n_s_blth, answer_value: 1, response: @response)
        create(:answer, question: @n_v_blth, answer_value: 1, response: @response)
        create(:answer, question: @n_fert, answer_value: 1, response: @response)
        create(:answer, question: @n_embrec, answer_value: 1, response: @response)
        # Sum right-side
        create(:answer, question: @n_bl_et, answer_value: 0, response: @response)
        create(:answer, question: @n_cl_et, answer_value: 0, response: @response)
        create(:answer, question: @n_clfz_s, answer_value: 0, response: @response)
        create(:answer, question: @n_clfz_v, answer_value: 0, response: @response)
        create(:answer, question: @n_blfz_s, answer_value: 0, response: @response)
        create(:answer, question: @n_blfz_v, answer_value: 0, response: @response)
        create(:answer, question: @n_embdisp, answer_value: 0, response: @response)
        answer.reload
        expect(@cqv.check(answer)).to be_nil
      end

      it 'should fail when n_s_clth sum less than n_bl_et sum' do
        answer = create(:answer, question: @n_s_clth, answer_value: 0, response: @response)
        create(:answer, question: @n_v_clth, answer_value: 0, response: @response)
        create(:answer, question: @n_s_blth, answer_value: 0, response: @response)
        create(:answer, question: @n_v_blth, answer_value: 0, response: @response)
        create(:answer, question: @n_fert, answer_value: 0, response: @response)
        create(:answer, question: @n_embrec, answer_value: 0, response: @response)
        # Sum right-side
        create(:answer, question: @n_bl_et, answer_value: 1, response: @response)
        create(:answer, question: @n_cl_et, answer_value: 1, response: @response)
        create(:answer, question: @n_clfz_s, answer_value: 1, response: @response)
        create(:answer, question: @n_clfz_v, answer_value: 1, response: @response)
        create(:answer, question: @n_blfz_s, answer_value: 1, response: @response)
        create(:answer, question: @n_blfz_v, answer_value: 1, response: @response)
        create(:answer, question: @n_embdisp, answer_value: 1, response: @response)
        answer.reload
        expect(@cqv.check(answer)).to eq('My error message')
      end
    end
  end

  describe 'RULE: special_rule_pr_clin' do
    # special_rule_pr_clin: if pr_clin is y or u, n_bl_et>0 |n_cl_et >0 | iui_date is a date
    before(:each) do
      @survey = create(:survey)
      @section = create(:section, survey: @survey)
      @pr_clin = create(:question, code: 'PR_CLIN', section: @section, question_type: Question::TYPE_CHOICE)
      @n_bl_et = create(:question, code: 'N_BL_ET', section: @section, question_type: Question::TYPE_INTEGER)
      @n_cl_et = create(:question, code: 'N_CL_ET', section: @section, question_type: Question::TYPE_INTEGER)
      @iui_date = create(:question, code: 'IUI_DATE', section: @section, question_type: Question::TYPE_DATE)
      @cqv = create(:cross_question_validation, rule: 'special_rule_pr_clin', question: @pr_clin, error_message: 'My error message', related_question_id: nil)
      @response = create(:response, survey: @survey)
    end

    it 'should raise an error if used on the wrong question' do
      q = create(:question, code: 'Blah')
      cqv = build(:cross_question_validation, rule: 'special_rule_pr_clin', question: q)
      expect(cqv.valid?).to be false
      expect(cqv.errors[:base]).to eq ['special_rule_pr_clin requires question code PR_CLIN but got Blah']
    end

    it 'should pass when pr_clin is not y or u' do
      answer = create(:answer, question: @pr_clin, answer_value: 'n', response: @response)
      answer.reload
      expect(@cqv.check(answer)).to be_nil
    end

    ['y', 'u'].each do |pr_clin_trigger_value|
      describe "when pr_clin is #{pr_clin_trigger_value}" do
        before :each do
          @answer = create(:answer, question: @pr_clin, answer_value: pr_clin_trigger_value, response: @response)
          @answer.reload
        end

        it 'should fail when neither n_bl_et, n_cl_et or iui_date is answered' do
          expect(@cqv.check(@answer)).to eq('My error message')
        end

        it 'should fail when neither n_bl_et or n_cl_et is greater than 0 and iui_date is unanswered' do
          create(:answer, question: @n_bl_et, answer_value: -1, response: @response)
          create(:answer, question: @n_cl_et, answer_value: -1, response: @response)
          @answer.reload
          expect(@cqv.check(@answer)).to eq('My error message')
        end

        it 'should pass when n_bl_et > 0' do
          create(:answer, question: @n_bl_et, answer_value: 1, response: @response)
          @answer.reload
          expect(@cqv.check(@answer)).to be_nil
        end

        it 'should pass when n_cl_et > 0' do
          create(:answer, question: @n_cl_et, answer_value: 1, response: @response)
          @answer.reload
          expect(@cqv.check(@answer)).to be_nil
        end

        it 'should pass when iui_date is a date' do
          create(:answer, question: @iui_date, answer_value: '2013-01-02', response: @response)
          @answer.reload
          expect(@cqv.check(@answer)).to be_nil
        end
      end
    end
  end

  describe 'RULE: special_rule_gest_iui_date' do
    # special_rule_gest_iui_date: if gestational age (pr_end_dt - iui_date) is greater than 20 weeks, n_deliv must be present
    before :each do
      @survey = create(:survey)
      @section = create(:section, survey: @survey)
      @pr_end_dt = create(:question, code: 'PR_END_DT', section: @section, question_type: Question::TYPE_DATE)
      @iui_date = create(:question, code: 'IUI_DATE', section: @section, question_type: Question::TYPE_DATE)
      @n_deliv = create(:question, code: 'N_DELIV', section: @section, question_type: Question::TYPE_INTEGER)
      @cqv = create(:cross_question_validation, rule: 'special_rule_gest_iui_date', question: @n_deliv, error_message: 'My error message', related_question_id: nil)
      @response = create(:response, survey: @survey)
    end

    it 'should raise an error if used on the wrong question' do
      q = create(:question, code: 'Blah')
      cqv = build(:cross_question_validation, rule: 'special_rule_gest_iui_date', question: q)
      expect(cqv.valid?).to be false
      expect(cqv.errors[:base]).to eq ['special_rule_gest_iui_date requires question code N_DELIV but got Blah']
    end

    it 'should apply even when N_DELIV is unanswered' do
      expect(SpecialRules::RULES_THAT_APPLY_EVEN_WHEN_ANSWER_NIL).to include('special_rule_gest_iui_date')
    end

    it 'should pass if pr_end_dt is unanswered' do
      answer = create(:answer, question: @n_deliv, answer_value: nil, response: @response)
      create(:answer, question: @iui_date, answer_value: '2013-01-01', response: @response)
      answer.reload
      expect(@cqv.check(answer)).to be_nil
    end

    it 'should pass if iui_dt is unanswered' do
      answer = create(:answer, question: @n_deliv, answer_value: nil, response: @response)
      create(:answer, question: @pr_end_dt, answer_value: '2013-05-21', response: @response)
      answer.reload
      expect(@cqv.check(answer)).to be_nil
    end

    it 'should pass if gestational age (pr_end_dt - iui_date) is not greater than 20 weeks' do
      answer = create(:answer, question: @n_deliv, answer_value: nil, response: @response)
      create(:answer, question: @pr_end_dt, answer_value: '2013-05-21', response: @response) # 20 week difference
      create(:answer, question: @iui_date, answer_value: '2013-01-01', response: @response)
      answer.reload
      expect(@cqv.check(answer)).to be_nil
    end

    describe 'when gestational age (pr_end_dt - iui_date) is greater than 20 weeks' do
      it 'should fail if n_deliv is not present' do
        answer = create(:answer, question: @n_deliv, answer_value: nil, response: @response)
        create(:answer, question: @pr_end_dt, answer_value: '2013-05-22', response: @response) # 20 week + 1 day difference
        create(:answer, question: @iui_date, answer_value: '2013-01-01', response: @response)
        answer.reload
        expect(@cqv.check(answer)).to eq('My error message')
      end

      it 'should pass if n_deliv is present' do
        answer = create(:answer, question: @n_deliv, answer_value: 1, response: @response)
        create(:answer, question: @pr_end_dt, answer_value: '2013-05-22', response: @response) # 20 week + 1 day difference
        create(:answer, question: @iui_date, answer_value: '2013-01-01', response: @response)
        answer.reload
        expect(@cqv.check(answer)).to be_nil
      end
    end
  end

  describe 'RULE: special_rule_gest_et_date' do
    # special_rule_gest_et_date: if gestational age (pr_end_dt - et_date) is greater than 20 weeks, n_deliv must be present
    before :each do
      @survey = create(:survey)
      @section = create(:section, survey: @survey)
      @pr_end_dt = create(:question, code: 'PR_END_DT', section: @section, question_type: Question::TYPE_DATE)
      @et_date = create(:question, code: 'ET_DATE', section: @section, question_type: Question::TYPE_DATE)
      @n_deliv = create(:question, code: 'N_DELIV', section: @section, question_type: Question::TYPE_INTEGER)
      @cqv = create(:cross_question_validation, rule: 'special_rule_gest_et_date', question: @n_deliv, error_message: 'My error message', related_question_id: nil)
      @response = create(:response, survey: @survey)
    end

    it 'should raise an error if used on the wrong question' do
      q = create(:question, code: 'Blah')
      cqv = build(:cross_question_validation, rule: 'special_rule_gest_et_date', question: q)
      expect(cqv.valid?).to be false
      expect(cqv.errors[:base]).to eq ['special_rule_gest_et_date requires question code N_DELIV but got Blah']
    end

    it 'should apply even when N_DELIV is unanswered' do
      expect(SpecialRules::RULES_THAT_APPLY_EVEN_WHEN_ANSWER_NIL).to include('special_rule_gest_et_date')
    end

    it 'should pass if pr_end_dt is unanswered' do
      answer = create(:answer, question: @n_deliv, answer_value: nil, response: @response)
      create(:answer, question: @et_date, answer_value: '2013-01-01', response: @response)
      answer.reload
      expect(@cqv.check(answer)).to be_nil
    end

    it 'should pass if et_date is unanswered' do
      answer = create(:answer, question: @n_deliv, answer_value: nil, response: @response)
      create(:answer, question: @et_date, answer_value: '2013-05-21', response: @response)
      answer.reload
      expect(@cqv.check(answer)).to be_nil
    end

    it 'should pass if gestational age (pr_end_dt - et_date) is not greater than 20 weeks' do
      answer = create(:answer, question: @n_deliv, answer_value: nil, response: @response)
      create(:answer, question: @pr_end_dt, answer_value: '2013-05-21', response: @response) # 20 week difference
      create(:answer, question: @et_date, answer_value: '2013-01-01', response: @response)
      answer.reload
      expect(@cqv.check(answer)).to be_nil
    end

    describe 'when gestational age (pr_end_dt - et_date) is greater than 20 weeks' do
      it 'should fail if n_deliv is not present' do
        answer = create(:answer, question: @n_deliv, answer_value: nil, response: @response)
        create(:answer, question: @pr_end_dt, answer_value: '2013-05-22', response: @response) # 20 week + 1 day difference
        create(:answer, question: @et_date, answer_value: '2013-01-01', response: @response)
        answer.reload
        expect(@cqv.check(answer)).to eq('My error message')
      end

      it 'should pass if n_deliv is present' do
        answer = create(:answer, question: @n_deliv, answer_value: 1, response: @response)
        create(:answer, question: @pr_end_dt, answer_value: '2013-05-22', response: @response) # 20 week + 1 day difference
        create(:answer, question: @et_date, answer_value: '2013-01-01', response: @response)
        answer.reload
        expect(@cqv.check(answer)).to be_nil
      end
    end
  end

  describe 'RULE: special_rule_thaw_don' do
    # special_rule_thaw_don: if (n_s_clth + n_v_clth + n_s_blth + n_v_blth) > 0 and don_age is complete, thaw_don must be complete
    before :each do
      @survey = create(:survey)
      @section = create(:section, survey: @survey)
      @n_s_clth = create(:question, code: 'N_S_CLTH', section: @section, question_type: Question::TYPE_INTEGER)
      @n_v_clth = create(:question, code: 'N_V_CLTH', section: @section, question_type: Question::TYPE_INTEGER)
      @n_s_blth = create(:question, code: 'N_S_BLTH', section: @section, question_type: Question::TYPE_INTEGER)
      @n_v_blth = create(:question, code: 'N_V_BLTH', section: @section, question_type: Question::TYPE_INTEGER)
      @don_age = create(:question, code: 'DON_AGE', section: @section, question_type: Question::TYPE_INTEGER)
      @thaw_don = create(:question, code: 'THAW_DON', section: @section, question_type: Question::TYPE_CHOICE)
      @cqv = create(:cross_question_validation, rule: 'special_rule_thaw_don', question: @thaw_don, error_message: 'My error message', related_question_id: nil)
      @response = create(:response, survey: @survey)
    end

    it 'should raise an error if used on the wrong question' do
      q = create(:question, code: 'Blah')
      cqv = build(:cross_question_validation, rule: 'special_rule_thaw_don', question: q)
      expect(cqv.valid?).to be false
      expect(cqv.errors[:base]).to eq ['special_rule_thaw_don requires question code THAW_DON but got Blah']
    end

    it 'should apply even when THAW_DON is unanswered' do
      expect(SpecialRules::RULES_THAT_APPLY_EVEN_WHEN_ANSWER_NIL).to include('special_rule_thaw_don')
    end

    it 'should pass when don_age is not complete' do
      answer = create(:answer, question: @thaw_don, answer_value: nil, response: @response)
      answer.reload
      expect(@cqv.check(answer)).to be_nil
    end

    describe 'when don_age is complete' do
      before :each do
        @answer = create(:answer, question: @thaw_don, answer_value: nil, response: @response)
        create(:answer, question: @don_age, answer_value: 20, response: @response)
        @answer.reload
      end

      describe 'when n_s_clth is unanswered' do
        it 'should pass when (n_v_clth + n_s_blth + n_v_blth) is not greater than 0' do
          create(:answer, question: @n_v_clth, answer_value: -1, response: @response)
          create(:answer, question: @n_s_blth, answer_value: -1, response: @response)
          create(:answer, question: @n_v_blth, answer_value: -1, response: @response)
          @answer.reload
          expect(@cqv.check(@answer)).to be_nil
        end

        describe 'when n_v_clth is unanswered' do
          it 'should pass when (n_s_blth + n_v_blth) is not greater than 0' do
            create(:answer, question: @n_s_blth, answer_value: -1, response: @response)
            create(:answer, question: @n_v_blth, answer_value: -1, response: @response)
            @answer.reload
            expect(@cqv.check(@answer)).to be_nil
          end

          describe 'when n_s_blth is unanswered' do
            it 'should pass when n_v_blth is not greater than 0' do
              create(:answer, question: @n_v_blth, answer_value: -1, response: @response)
              @answer.reload
              expect(@cqv.check(@answer)).to be_nil
            end

            describe 'when n_v_blth is unanswered' do
              it 'should pass' do
                expect(@cqv.check(@answer)).to be_nil
              end
            end
          end
        end
      end

      it 'should pass when (n_s_clth + n_v_clth + n_s_blth + n_v_blth) is not greater than 0' do
        create(:answer, question: @n_s_clth, answer_value: 0, response: @response)
        create(:answer, question: @n_v_clth, answer_value: 0, response: @response)
        create(:answer, question: @n_s_blth, answer_value: 0, response: @response)
        create(:answer, question: @n_v_blth, answer_value: 0, response: @response)
        @answer.reload
        expect(@cqv.check(@answer)).to be_nil
      end

      describe 'when (n_s_clth + n_v_clth + n_s_blth + n_v_blth) > 0' do
        before :each do
          create(:answer, question: @n_s_clth, answer_value: 1, response: @response)
          create(:answer, question: @n_v_clth, answer_value: 1, response: @response)
          create(:answer, question: @n_s_blth, answer_value: 1, response: @response)
          create(:answer, question: @n_v_blth, answer_value: 1, response: @response)
          @answer.reload
        end

        it 'should fail if thaw_don is not complete' do
          expect(@cqv.check(@answer)).to eq('My error message')
        end
      end
    end

    it 'should pass if don_age is complete, (n_s_clth + n_v_clth + n_s_blth + n_v_blth) > 0 and thaw_don is complete' do
      answer = create(:answer, question: @thaw_don, answer_value: 0, response: @response)
      create(:answer, question: @don_age, answer_value: 20, response: @response)
      create(:answer, question: @n_s_clth, answer_value: 1, response: @response)
      create(:answer, question: @n_v_clth, answer_value: 1, response: @response)
      create(:answer, question: @n_s_blth, answer_value: 1, response: @response)
      create(:answer, question: @n_v_blth, answer_value: 1, response: @response)
      answer.reload
      expect(@cqv.check(answer)).to be_nil
    end
  end

  describe 'Rule: special_rule_surr' do
    # special_rule_surr: if surr=y & (n_s_clth + n_v_clth + n_s_blth + n_v_blth) > 0, don_age must be present
    before :each do
      @survey = create(:survey)
      @section = create(:section, survey: @survey)
      @surr = create(:question, code: 'SURR', section: @section, question_type: Question::TYPE_CHOICE)
      @n_s_clth = create(:question, code: 'N_S_CLTH', section: @section, question_type: Question::TYPE_INTEGER)
      @n_v_clth = create(:question, code: 'N_V_CLTH', section: @section, question_type: Question::TYPE_INTEGER)
      @n_s_blth = create(:question, code: 'N_S_BLTH', section: @section, question_type: Question::TYPE_INTEGER)
      @n_v_blth = create(:question, code: 'N_V_BLTH', section: @section, question_type: Question::TYPE_INTEGER)
      @don_age = create(:question, code: 'DON_AGE', section: @section, question_type: Question::TYPE_INTEGER)
      @cqv = create(:cross_question_validation, rule: 'special_rule_surr', question: @don_age, error_message: 'My error message', related_question_id: nil)
      @response = create(:response, survey: @survey)
    end

    it 'should raise an error if used on the wrong question' do
      q = create(:question, code: 'Blah')
      cqv = build(:cross_question_validation, rule: 'special_rule_surr', question: q)
      expect(cqv.valid?).to be false
      expect(cqv.errors[:base]).to eq ['special_rule_surr requires question code DON_AGE but got Blah']
    end

    it 'should apply even when DON_AGE is unanswered' do
      expect(SpecialRules::RULES_THAT_APPLY_EVEN_WHEN_ANSWER_NIL).to include('special_rule_surr')
    end

    it 'should pass when surr != y' do
      answer = create(:answer, question: @don_age, answer_value: nil, response: @response)
      create(:answer, question: @surr, answer_value: 'n', response: @response)
      answer.reload
      expect(@cqv.check(answer)).to be_nil
    end

    describe 'when surr == y' do
      before :each do
        @answer = create(:answer, question: @don_age, answer_value: nil, response: @response)
        create(:answer, question: @surr, answer_value: 'y', response: @response)
        @answer.reload
      end

      describe 'when n_s_clth is unanswered' do
        it 'should pass when (n_v_clth + n_s_blth + n_v_blth) is not greater than 0' do
          create(:answer, question: @n_v_clth, answer_value: -1, response: @response)
          create(:answer, question: @n_s_blth, answer_value: -1, response: @response)
          create(:answer, question: @n_v_blth, answer_value: -1, response: @response)
          @answer.reload
          expect(@cqv.check(@answer)).to be_nil
        end

        describe 'when n_v_clth is unanswered' do
          it 'should pass when (n_s_blth + n_v_blth) is not greater than 0' do
            create(:answer, question: @n_s_blth, answer_value: -1, response: @response)
            create(:answer, question: @n_v_blth, answer_value: -1, response: @response)
            @answer.reload
            expect(@cqv.check(@answer)).to be_nil
          end

          describe 'when n_s_blth is unanswered' do
            it 'should pass when n_v_blth is not greater than 0' do
              create(:answer, question: @n_v_blth, answer_value: -1, response: @response)
              @answer.reload
              expect(@cqv.check(@answer)).to be_nil
            end

            describe 'when n_v_blth is unanswered' do
              it 'should pass' do
                expect(@cqv.check(@answer)).to be_nil
              end
            end
          end
        end
      end

      it 'should pass when (n_s_clth + n_v_clth + n_s_blth + n_v_blth) is not greater than 0' do
        create(:answer, question: @n_s_clth, answer_value: -1, response: @response)
        create(:answer, question: @n_v_clth, answer_value: -1, response: @response)
        create(:answer, question: @n_s_blth, answer_value: -1, response: @response)
        create(:answer, question: @n_v_blth, answer_value: -1, response: @response)
        @answer.reload
        expect(@cqv.check(@answer)).to be_nil
      end

      describe 'when (n_s_clth + n_v_clth + n_s_blth + n_v_blth) > 0' do
        before :each do
          create(:answer, question: @n_s_clth, answer_value: 1, response: @response)
          create(:answer, question: @n_v_clth, answer_value: 1, response: @response)
          create(:answer, question: @n_s_blth, answer_value: 1, response: @response)
          create(:answer, question: @n_v_blth, answer_value: 1, response: @response)
          @answer.reload
        end

        it 'should fail when don_age is not present' do
          expect(@cqv.check(@answer)).to eq('My error message')
        end
      end
    end

    it 'should pass when surr == y, (n_s_clth + n_v_clth + n_s_blth + n_v_blth) > 0 and don_age is present' do
      answer = create(:answer, question: @don_age, answer_value: 20, response: @response)
      create(:answer, question: @surr, answer_value: 'y', response: @response)
      create(:answer, question: @n_s_clth, answer_value: 1, response: @response)
      create(:answer, question: @n_v_clth, answer_value: 1, response: @response)
      create(:answer, question: @n_s_blth, answer_value: 1, response: @response)
      create(:answer, question: @n_v_blth, answer_value: 1, response: @response)
      expect(@cqv.check(answer)).to be_nil
    end
  end

  describe 'Rule: special_rule_mtage' do
    # special_rule_mtage: if n_embdisp =0, cyc_date-fdob must be ≥ 18 years & cyc_date-fdob must be <= 55 years
    # i.e if n_embdisp == 0 then cyc_date ≥ fdob + 18 years && cyc_date <= fdob + 55 years
    before :each do
      @survey = create(:survey)
      @section = create(:section, survey: @survey)
      @n_embdisp = create(:question, code: 'N_EMBDISP', section: @section, question_type: Question::TYPE_INTEGER)
      @cyc_date = create(:question, code: 'CYC_DATE', section: @section, question_type: Question::TYPE_DATE)
      @fdob = create(:question, code: 'FDOB', section: @section, question_type: Question::TYPE_DATE)
      @cqv = create(:cross_question_validation, rule: 'special_rule_mtage', question: @n_embdisp, error_message: 'My error message', related_question_id: nil)
      @response = create(:response, survey: @survey)
    end

    it 'should raise an error if used on the wrong question' do
      q = create(:question, code: 'Blah')
      cqv = build(:cross_question_validation, rule: 'special_rule_mtage', question: q)
      expect(cqv.valid?).to be false
      expect(cqv.errors[:base]).to eq ['special_rule_mtage requires question code N_EMBDISP but got Blah']
    end

    it 'should pass if n_embdisp != 0' do
      [-1, 1].each do |val|
        answer = create(:answer, question: @n_embdisp, answer_value: val, response: @response)
        answer.reload
        expect(@cqv.check(answer)).to be_nil
      end
    end

    describe 'when n_embdisp == 0' do
      before :each do
        @answer = create(:answer, question: @n_embdisp, answer_value: 0, response: @response)
        @answer.reload
      end

      it 'should pass when cyc_date is unanswered' do
        create(:answer, question: @fdob, answer_value: '2000-01-01', response: @response)
        @answer.reload
        expect(@cqv.check(@answer)).to be_nil
      end

      it 'should pass when fdob is unanswered' do
        create(:answer, question: @cyc_date, answer_value: '2000-01-01', response: @response)
        @answer.reload
        expect(@cqv.check(@answer)).to be_nil
      end

      it 'should fail when cyc_date-fdob is < 18 years' do
        # date difference is 18 years minus 1 day
        create(:answer, question: @cyc_date, answer_value: '2017-12-31', response: @response)
        create(:answer, question: @fdob, answer_value: '2000-01-01', response: @response)
        @answer.reload
        expect(@cqv.check(@answer)).to eq('My error message')
      end

      it 'should fail when cyc_date-fdob is > 55 years' do
        # date difference is 55 years plus 1 day
        create(:answer, question: @cyc_date, answer_value: '2056-01-01', response: @response)
        create(:answer, question: @fdob, answer_value: '2000-01-01', response: @response)
        @answer.reload
        expect(@cqv.check(@answer)).to eq('My error message')
      end

      describe 'when cyc_date-fdob is ≥ 18 years & <= 55 years' do
        it 'should pass when cyc_date-fdob is == 18 years' do
          create(:answer, question: @cyc_date, answer_value: '2018-01-01', response: @response)
          create(:answer, question: @fdob, answer_value: '2000-01-01', response: @response)
          @answer.reload
          expect(@cqv.check(@answer)).to be_nil
        end

        it 'should pass when cyc_date-fdob is == 55 years' do
          create(:answer, question: @cyc_date, answer_value: '2055-01-01', response: @response)
          create(:answer, question: @fdob, answer_value: '2000-01-01', response: @response)
          @answer.reload
          expect(@cqv.check(@answer)).to be_nil
        end

        it 'should pass when cyc_date-fdob is > 18 & < 55 years' do
          create(:answer, question: @cyc_date, answer_value: '2035-10-15', response: @response)
          create(:answer, question: @fdob, answer_value: '2000-11-06', response: @response)
          @answer.reload
          expect(@cqv.check(@answer)).to be_nil
        end
      end
    end
  end

  describe 'Rule: special_rule_mtagedisp' do
    # special_rule_mtagedisp: if n_embdisp >0, cyc_date-fdob must be ≥ 18 years & <= 70 years
    # i.e. if n_embdisp > 0 then cyc_date ≥ fdob + 18 years && cyc_date <= fdob + 70 years
    before :each do
      @survey = create(:survey)
      @section = create(:section, survey: @survey)
      @n_embdisp = create(:question, code: 'N_EMBDISP', section: @section, question_type: Question::TYPE_INTEGER)
      @cyc_date = create(:question, code: 'CYC_DATE', section: @section, question_type: Question::TYPE_DATE)
      @fdob = create(:question, code: 'FDOB', section: @section, question_type: Question::TYPE_DATE)
      @cqv = create(:cross_question_validation, rule: 'special_rule_mtagedisp', question: @n_embdisp, error_message: 'My error message', related_question_id: nil)
      @response = create(:response, survey: @survey)
    end

    it 'should raise an error if used on the wrong question' do
      q = create(:question, code: 'Blah')
      cqv = build(:cross_question_validation, rule: 'special_rule_mtagedisp', question: q)
      expect(cqv.valid?).to be false
      expect(cqv.errors[:base]).to eq ['special_rule_mtagedisp requires question code N_EMBDISP but got Blah']
    end

    it 'should pass if n_embdisp <= 0' do
      [-1, 0].each do |val|
        answer = create(:answer, question: @n_embdisp, answer_value: val, response: @response)
        answer.reload
        expect(@cqv.check(answer)).to be_nil
      end
    end

    describe 'when n_embdisp > 0' do
      before :each do
        @answer = create(:answer, question: @n_embdisp, answer_value: 1, response: @response)
        @answer.reload
      end

      it 'should pass when cyc_date is unanswered' do
        create(:answer, question: @fdob, answer_value: '2000-01-01', response: @response)
        @answer.reload
        expect(@cqv.check(@answer)).to be_nil
      end

      it 'should pass when fdob is unanswered' do
        create(:answer, question: @cyc_date, answer_value: '2000-01-01', response: @response)
        @answer.reload
        expect(@cqv.check(@answer)).to be_nil
      end

      it 'should fail when cyc_date-fdob is < 18 years' do
        # date difference is 18 years minus 1 day
        create(:answer, question: @cyc_date, answer_value: '2017-12-31', response: @response)
        create(:answer, question: @fdob, answer_value: '2000-01-01', response: @response)
        @answer.reload
        expect(@cqv.check(@answer)).to eq('My error message')
      end

      it 'should fail when cyc_date-fdob is > 70 years' do
        # date difference is 70 years plus 1 day
        create(:answer, question: @cyc_date, answer_value: '2071-01-01', response: @response)
        create(:answer, question: @fdob, answer_value: '2000-01-01', response: @response)
        @answer.reload
        expect(@cqv.check(@answer)).to eq('My error message')
      end

      describe 'when cyc_date-fdob is ≥ 18 years & <= 70 years' do
        it 'should pass when cyc_date-fdob is == 18 years' do
          create(:answer, question: @cyc_date, answer_value: '2018-01-01', response: @response)
          create(:answer, question: @fdob, answer_value: '2000-01-01', response: @response)
          @answer.reload
          expect(@cqv.check(@answer)).to be_nil
        end

        it 'should pass when cyc_date-fdob is == 70 years' do
          create(:answer, question: @cyc_date, answer_value: '2070-01-01', response: @response)
          create(:answer, question: @fdob, answer_value: '2000-01-01', response: @response)
          @answer.reload
          expect(@cqv.check(@answer)).to be_nil
        end

        it 'should pass when cyc_date-fdob is > 18 & < 70 years' do
          create(:answer, question: @cyc_date, answer_value: '2050-10-15', response: @response)
          create(:answer, question: @fdob, answer_value: '2000-11-06', response: @response)
          @answer.reload
          expect(@cqv.check(@answer)).to be_nil
        end
      end
    end
  end

  describe 'Rule: special_rule_et_date' do
    # special_rule_et_date: if et_date is a date, n_cl_et must be >=0 | n_bl_et must be >=0
    before :each do
      @survey = create(:survey)
      @section = create(:section, survey: @survey)
      @et_date = create(:question, code: 'ET_DATE', section: @section, question_type: Question::TYPE_DATE)
      @n_cl_et = create(:question, code: 'N_CL_ET', section: @section, question_type: Question::TYPE_INTEGER)
      @n_bl_et = create(:question, code: 'N_BL_ET', section: @section, question_type: Question::TYPE_INTEGER)
      @cqv = create(:cross_question_validation, rule: 'special_rule_et_date', question: @et_date, error_message: 'My error message', related_question_id: nil)
      @response = create(:response, survey: @survey)
    end

    it 'should raise an error if used on the wrong question' do
      q = create(:question, code: 'Blah')
      cqv = build(:cross_question_validation, rule: 'special_rule_et_date', question: q)
      expect(cqv.valid?).to be false
      expect(cqv.errors[:base]).to eq ['special_rule_et_date requires question code ET_DATE but got Blah']
    end

    describe 'when et_date is a date' do
      before :each do
        @answer = create(:answer, question: @et_date, answer_value: '2000-01-01', response: @response)
        @answer.reload
      end

      it 'should fail when neither n_cl_et or n_bl_et is answered' do
        expect(@cqv.check(@answer)).to eq('My error message')
      end

      describe 'when n_cl_et is answered and n_bl_et is unanswered' do
        it 'should pass if n_cl_et > 0' do
          create(:answer, question: @n_cl_et, answer_value: 1, response: @response)
          @answer.reload
          expect(@cqv.check(@answer)).to be_nil
        end

        it 'should pass if n_cl_et == 0' do
          create(:answer, question: @n_cl_et, answer_value: 0, response: @response)
          @answer.reload
          expect(@cqv.check(@answer)).to be_nil
        end

        it 'should fail when n_cl_et < 0' do
          create(:answer, question: @n_cl_et, answer_value: -1, response: @response)
          @answer.reload
          expect(@cqv.check(@answer)).to eq('My error message')
        end
      end

      describe 'when n_cl_et is unanswered and n_bl_et is answered' do
        it 'should pass if n_bl_et > 0' do
          create(:answer, question: @n_bl_et, answer_value: 1, response: @response)
          @answer.reload
          expect(@cqv.check(@answer)).to be_nil
        end

        it 'should pass if n_bl_et == 0' do
          create(:answer, question: @n_bl_et, answer_value: 0, response: @response)
          @answer.reload
          expect(@cqv.check(@answer)).to be_nil
        end

        it 'should fail when n_bl_et < 0' do
          create(:answer, question: @n_bl_et, answer_value: -1, response: @response)
          @answer.reload
          expect(@cqv.check(@answer)).to eq('My error message')
        end
      end
    end
  end

  describe 'Rule: special_rule_stim_1st' do
    # special_rule_stim_1st: if stim_1st=y, opu_date must be complete| can_date must be complete
    before :each do
      @survey = create(:survey)
      @section = create(:section, survey: @survey)
      @stim_1st = create(:question, code: 'STIM_1ST', section: @section, question_type: Question::TYPE_CHOICE)
      @opu_date = create(:question, code: 'OPU_DATE', section: @section, question_type: Question::TYPE_DATE)
      @can_date = create(:question, code: 'CAN_DATE', section: @section, question_type: Question::TYPE_DATE)
      @cqv = create(:cross_question_validation, rule: 'special_rule_stim_1st', question: @stim_1st, error_message: 'My error message', related_question_id: nil)
      @response = create(:response, survey: @survey)
    end

    it 'should raise an error if used on the wrong question' do
      q = create(:question, code: 'Blah')
      cqv = build(:cross_question_validation, rule: 'special_rule_stim_1st', question: q)
      expect(cqv.valid?).to be false
      expect(cqv.errors[:base]).to eq ['special_rule_stim_1st requires question code STIM_1ST but got Blah']
    end

    it 'should pass if stim_1st == n' do
      answer = create(:answer, question: @stim_1st, answer_value: 'n', response: @response)
      answer.reload
      expect(@cqv.check(answer)).to be_nil
    end

    describe 'when stim_1st == y' do
      before :each do
        @answer = create(:answer, question: @stim_1st, answer_value: 'y', response: @response)
        @answer.reload
      end

      it 'should fail if neither opu_date or can_date is answered' do
        expect(@cqv.check(@answer)).to eq('My error message')
      end

      it 'should pass if opu_date is answered' do
        create(:answer, question: @opu_date, answer_value: '2000-01-01', response: @response)
        @answer.reload
        expect(@cqv.check(@answer)).to be_nil
      end

      it 'should pass if can_date is answered' do
        create(:answer, question: @can_date, answer_value: '2000-01-01', response: @response)
        @answer.reload
        expect(@cqv.check(@answer)).to be_nil
      end
    end
  end

end
