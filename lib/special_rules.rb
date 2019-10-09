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

class SpecialRules

  # NOTE: Special rules involving choice question options should use a lowercase comparison, as the choice answer is
  #        downcast on batch file ingest and on survey question option save. Failing to do so may cause rules not to
  #        trigger as expected.

  RULES_THAT_APPLY_EVEN_WHEN_ANSWER_NIL = %w(
    special_rule_comp1
    special_rule_comp3
    special_rule_gest_iui_date
    special_rule_gest_et_date
    special_rule_thaw_don
    special_rule_surr
  )

  RULE_CODES_REQUIRING_PARTICULAR_QUESTION_CODES = {
    'special_rule_comp1' => 'N_V_EGTH',
    'special_rule_comp2' => 'N_FERT',
    'special_rule_comp3' => 'N_S_CLTH',
    'special_rule_mtage' => 'N_EMBDISP',
    'special_rule_mtagedisp' => 'N_EMBDISP',
    'special_rule_pr_clin' => 'PR_CLIN',
    'special_rule_gest_iui_date' => 'N_DELIV',
    'special_rule_gest_et_date' => 'N_DELIV',
    'special_rule_thaw_don' => 'THAW_DON',
    'special_rule_surr' => 'DON_AGE',
    'special_rule_et_date' => 'ET_DATE',
    'special_rule_stim_1st' => 'STIM_1ST',
    'special_rule_pgt_2' => 'N_PGT_ET',
    'special_rule_pgt_3' => 'N_PGT_TH',
    'special_rule_surr_2' => 'CYCLE_TYPE',
    'special_rule_surr_3' => 'SURR',
    'special_rule_surr_4' => 'SURR',
    'special_rule_surr_5' => 'SURR',
    'special_rule_cycletype_2_don' => 'CYCLE_TYPE',
    'special_rule_cycletype_2_rec' => 'CYCLE_TYPE',
    'special_rule_ttc' => 'PARENT_SEX'
  }

  def self.additional_cqv_validation(cqv)
    if cqv.rule and cqv.question
      required_question_code = RULE_CODES_REQUIRING_PARTICULAR_QUESTION_CODES[cqv.rule]
      actual_question_code = cqv.question.code
      if required_question_code and actual_question_code != required_question_code
	cqv.errors[:base] << "#{cqv.rule} requires question code #{required_question_code} but got #{actual_question_code}"
      end
    end
  end

  def self.register_additional_rules
    # put special rules here that aren't part of the generic rule set, that way they can easily be removed or replaced later

    # add to the list of rules with no related question
    CrossQuestionValidation.rules_with_no_related_question += %w(
      special_dob
      special_rule_comp1
      special_rule_comp2
      special_rule_comp3
      special_rule_mtage
      special_rule_mtagedisp
      special_rule_pr_clin
      special_rule_gest_iui_date
      special_rule_gest_et_date
      special_rule_thaw_don
      special_rule_surr
      special_rule_et_date
      special_rule_stim_1st
      special_rule_pgt_2
      special_rule_pgt_3
      special_rule_surr_2
      special_rule_surr_3
      special_rule_surr_4
      special_rule_surr_5
      special_rule_cycletype_2_don
      special_rule_cycletype_2_rec
      special_rule_ttc
    )

    CrossQuestionValidation.register_checker 'special_dob', lambda { |answer, unused_related_answer, checker_params|
      # DOB must be in the same year as the year of registration
      answer.date_answer.year == answer.response.year_of_registration
    }

    CrossQuestionValidation.register_checker 'special_rule_comp1', lambda { |answer, ununused_related_answer, checker_params|
      #special_rule_comp1: n_v_egth + n_s_egth + n_eggs + n_recvd >= n_donate + n_ivf + n_icsi + n_egfz_s + n_egfz_v
      raise 'Can only be used on question N_V_EGTH' unless answer.question.code == 'N_V_EGTH'

      n_v_egth = answer_or_0_if_nil answer.response.comparable_answer_or_nil_for_question_with_code('N_V_EGTH')
      n_s_egth = answer_or_0_if_nil answer.response.comparable_answer_or_nil_for_question_with_code('N_S_EGTH')
      n_eggs = answer_or_0_if_nil answer.response.comparable_answer_or_nil_for_question_with_code('N_EGGS')
      n_recvd = answer_or_0_if_nil answer.response.comparable_answer_or_nil_for_question_with_code('N_RECVD')
      n_donate = answer_or_0_if_nil answer.response.comparable_answer_or_nil_for_question_with_code('N_DONATE')
      n_ivf = answer_or_0_if_nil answer.response.comparable_answer_or_nil_for_question_with_code('N_IVF')
      n_icsi = answer_or_0_if_nil answer.response.comparable_answer_or_nil_for_question_with_code('N_ICSI')
      n_egfz_s = answer_or_0_if_nil answer.response.comparable_answer_or_nil_for_question_with_code('N_EGFZ_S')
      n_egfz_v = answer_or_0_if_nil answer.response.comparable_answer_or_nil_for_question_with_code('N_EGFZ_V')

      # Perform validation check
      (n_v_egth + n_s_egth + n_eggs + n_recvd) >= (n_donate + n_ivf + n_icsi + n_egfz_s + n_egfz_v)
    }

    CrossQuestionValidation.register_checker 'special_rule_comp2', lambda { |answer, ununused_related_answer, checker_params|
      # special_rule_comp2: n_ivf + n_icsi >=n_fert
      # i.e. n_fert <= n_ivf + n_icsi
      raise 'Can only be used on question N_FERT' unless answer.question.code == 'N_FERT'

      n_fert = answer.response.comparable_answer_or_nil_for_question_with_code('N_FERT')
      n_ivf = answer_or_0_if_nil answer.response.comparable_answer_or_nil_for_question_with_code('N_IVF')
      n_icsi = answer_or_0_if_nil answer.response.comparable_answer_or_nil_for_question_with_code('N_ICSI')

      n_fert <= (n_ivf + n_icsi)
    }

    CrossQuestionValidation.register_checker 'special_rule_comp3', lambda { |answer, ununused_related_answer, checker_params|
      # special_rule_comp3: (n_s_clth + n_v_clth + n_s_blth + n_v_blth + n_fert) >= (n_bl_et + n_cl_et + n_clfz_s + n_clfz_v + n_blfz_s + n_blfz_v)
      raise 'Can only be used on question N_S_CLTH' unless answer.question.code == 'N_S_CLTH'

      n_s_clth = answer_or_0_if_nil answer.response.comparable_answer_or_nil_for_question_with_code('N_S_CLTH')
      n_v_clth = answer_or_0_if_nil answer.response.comparable_answer_or_nil_for_question_with_code('N_V_CLTH')
      n_s_blth = answer_or_0_if_nil answer.response.comparable_answer_or_nil_for_question_with_code('N_S_BLTH')
      n_v_blth = answer_or_0_if_nil answer.response.comparable_answer_or_nil_for_question_with_code('N_V_BLTH')
      n_fert = answer_or_0_if_nil answer.response.comparable_answer_or_nil_for_question_with_code('N_FERT')
      n_bl_et = answer_or_0_if_nil answer.response.comparable_answer_or_nil_for_question_with_code('N_BL_ET')
      n_cl_et = answer_or_0_if_nil answer.response.comparable_answer_or_nil_for_question_with_code('N_CL_ET')
      n_clfz_s = answer_or_0_if_nil answer.response.comparable_answer_or_nil_for_question_with_code('N_CLFZ_S')
      n_clfz_v = answer_or_0_if_nil answer.response.comparable_answer_or_nil_for_question_with_code('N_CLFZ_V')
      n_blfz_s = answer_or_0_if_nil answer.response.comparable_answer_or_nil_for_question_with_code('N_BLFZ_S')
      n_blfz_v = answer_or_0_if_nil answer.response.comparable_answer_or_nil_for_question_with_code('N_BLFZ_V')

      (n_s_clth + n_v_clth + n_s_blth + n_v_blth + n_fert) >= (n_bl_et + n_cl_et + n_clfz_s + n_clfz_v + n_blfz_s + n_blfz_v)
    }

    CrossQuestionValidation.register_checker 'special_rule_mtage', lambda { |answer, ununused_related_answer, checker_params|
      # special_rule_mtage: if n_embdisp =0, cyc_date-fdob must be ≥ 18 years & cyc_date-fdob must be <= 55 years
      # i.e if n_embdisp == 0 then cyc_date ≥ fdob + 18 years && cyc_date <= fdob + 55 years
      raise 'Can only be used on question N_EMBDISP' unless answer.question.code == 'N_EMBDISP'

      n_embdisp = answer.response.comparable_answer_or_nil_for_question_with_code('N_EMBDISP')
      cyc_date = answer.response.comparable_answer_or_nil_for_question_with_code('CYC_DATE')
      fdob = answer.response.comparable_answer_or_nil_for_question_with_code('FDOB')

      break true if n_embdisp != 0
      break true if cyc_date.nil? || fdob.nil?
      year_diff = age_in_completed_years(fdob, cyc_date)
      year_diff >= 18 && year_diff <= 55
    }

    CrossQuestionValidation.register_checker 'special_rule_mtagedisp', lambda { |answer, ununused_related_answer, checker_params|
      # special_rule_mtagedisp: if n_embdisp >0, cyc_date-fdob must be ≥ 18 years & <= 70 years
      # i.e. if n_embdisp > 0 then cyc_date ≥ fdob + 18 years && cyc_date <= fdob + 70 years
      raise 'Can only be used on question N_EMBDISP' unless answer.question.code == 'N_EMBDISP'

      n_embdisp = answer.response.comparable_answer_or_nil_for_question_with_code('N_EMBDISP')
      cyc_date = answer.response.comparable_answer_or_nil_for_question_with_code('CYC_DATE')
      fdob = answer.response.comparable_answer_or_nil_for_question_with_code('FDOB')

      break true if n_embdisp <= 0
      break true if cyc_date.nil? || fdob.nil?
      year_diff = age_in_completed_years(fdob, cyc_date)
      year_diff >= 18 && year_diff <= 70
    }

    CrossQuestionValidation.register_checker 'special_rule_pr_clin', lambda { |answer, ununused_related_answer, checker_params|
      # special_rule_pr_clin: if pr_clin is y or u, n_bl_et>0 |n_cl_et >0 | iui_date is a date/present
      raise 'Can only be used on question PR_CLIN' unless answer.question.code == 'PR_CLIN'

      p_r_clin = answer.response.comparable_answer_or_nil_for_question_with_code('PR_CLIN')
      n_bl_et = answer.response.comparable_answer_or_nil_for_question_with_code('N_BL_ET')
      n_cl_et = answer.response.comparable_answer_or_nil_for_question_with_code('N_CL_ET')
      iui_date = answer.response.comparable_answer_or_nil_for_question_with_code('IUI_DATE')

      # If pr_clin not y or u, then validation passes and no more checks required
      break true unless (p_r_clin == 'y' || p_r_clin == 'u')

      # pr_clin is y or u, so do other checks and return valid if one passes
      (!n_bl_et.nil? && n_bl_et > 0) || (!n_cl_et.nil? && n_cl_et > 0) || !iui_date.nil?
    }

    CrossQuestionValidation.register_checker 'special_rule_gest_iui_date', lambda { |answer, ununused_related_answer, checker_params|
      # special_rule_gest_iui_date: if gestational age (pr_end_dt - iui_date) is greater than 20 weeks, n_deliv must be present
      raise 'Can only be used on question N_DELIV' unless answer.question.code == 'N_DELIV'

      pr_end_dt = answer.response.comparable_answer_or_nil_for_question_with_code('PR_END_DT')
      iui_date = answer.response.comparable_answer_or_nil_for_question_with_code('IUI_DATE')
      n_deliv = answer.response.comparable_answer_or_nil_for_question_with_code('N_DELIV')

      break true if pr_end_dt.nil? || iui_date.nil?
      break true if (pr_end_dt - iui_date) <= 140 # Pass if gest age is not greater than 20 weeks (in days)

      # Gest age is greater than 20 weeks (in days), check if n_deliv present
      !n_deliv.nil?
    }

    CrossQuestionValidation.register_checker 'special_rule_gest_et_date', lambda { |answer, ununused_related_answer, checker_params|
      # special_rule_gest_et_date: if gestational age (pr_end_dt - et_date) is greater than 20 weeks, n_deliv must be present
      raise 'Can only be used on question N_DELIV' unless answer.question.code == 'N_DELIV'

      pr_end_dt = answer.response.comparable_answer_or_nil_for_question_with_code('PR_END_DT')
      et_date = answer.response.comparable_answer_or_nil_for_question_with_code('ET_DATE')
      n_deliv = answer.response.comparable_answer_or_nil_for_question_with_code('N_DELIV')

      break true if pr_end_dt.nil? || et_date.nil?
      break true if (pr_end_dt - et_date) <= 140 # Pass if gest age is not greater than 20 weeks (in days)

      # Gest age is greater than 20 weeks (in days), check if n_deliv present
      !n_deliv.nil?
    }

    CrossQuestionValidation.register_checker 'special_rule_thaw_don', lambda { |answer, ununused_related_answer, checker_params|
      # special_rule_thaw_don: if (n_s_clth + n_v_clth + n_s_blth + n_v_blth) > 0 and don_age is complete, thaw_don must be complete
      raise 'Can only be used on question THAW_DON' unless answer.question.code == 'THAW_DON'

      n_s_clth = answer_or_0_if_nil answer.response.comparable_answer_or_nil_for_question_with_code('N_S_CLTH')
      n_v_clth = answer_or_0_if_nil answer.response.comparable_answer_or_nil_for_question_with_code('N_V_CLTH')
      n_s_blth = answer_or_0_if_nil answer.response.comparable_answer_or_nil_for_question_with_code('N_S_BLTH')
      n_v_blth = answer_or_0_if_nil answer.response.comparable_answer_or_nil_for_question_with_code('N_V_BLTH')
      don_age = answer.response.comparable_answer_or_nil_for_question_with_code('DON_AGE')
      thaw_don = answer.response.comparable_answer_or_nil_for_question_with_code('THAW_DON')

      break true if don_age.nil?
      break true if (n_s_clth + n_v_clth + n_s_blth + n_v_blth) <= 0
      !thaw_don.nil?
    }

    CrossQuestionValidation.register_checker 'special_rule_surr', lambda { |answer, ununused_related_answer, checker_params|
      # special_rule_surr: if surr=y & (n_s_clth + n_v_clth + n_s_blth + n_v_blth) > 0, don_age must be present
      raise 'Can only be used on question DON_AGE' unless answer.question.code == 'DON_AGE'

      surr = answer.response.comparable_answer_or_nil_for_question_with_code('SURR')
      n_s_clth = answer_or_0_if_nil answer.response.comparable_answer_or_nil_for_question_with_code('N_S_CLTH')
      n_v_clth = answer_or_0_if_nil answer.response.comparable_answer_or_nil_for_question_with_code('N_V_CLTH')
      n_s_blth = answer_or_0_if_nil answer.response.comparable_answer_or_nil_for_question_with_code('N_S_BLTH')
      n_v_blth = answer_or_0_if_nil answer.response.comparable_answer_or_nil_for_question_with_code('N_V_BLTH')
      don_age = answer.response.comparable_answer_or_nil_for_question_with_code('DON_AGE')

      break true if surr != 'y'
      break true if (n_s_clth + n_v_clth + n_s_blth + n_v_blth) <= 0
      !don_age.nil?
    }

    CrossQuestionValidation.register_checker 'special_rule_et_date', lambda { |answer, ununused_related_answer, checker_params|
      # special_rule_et_date: if et_date is a date, n_cl_et must be >0 | n_bl_et must be >0
      raise 'Can only be used on question ET_DATE' unless answer.question.code == 'ET_DATE'

      et_date = answer.response.comparable_answer_or_nil_for_question_with_code('ET_DATE')
      n_cl_et = answer.response.comparable_answer_or_nil_for_question_with_code('N_CL_ET')
      n_bl_et = answer.response.comparable_answer_or_nil_for_question_with_code('N_BL_ET')

      !et_date.nil? && ((!n_cl_et.nil? && n_cl_et > 0) || (!n_bl_et.nil? && n_bl_et > 0))
    }

    CrossQuestionValidation.register_checker 'special_rule_stim_1st', lambda { |answer, ununused_related_answer, checker_params|
      # special_rule_stim_1st: if stim_1st=y, opu_date must be complete| can_date must be complete
      raise 'Can only be used on question STIM_1ST' unless answer.question.code == 'STIM_1ST'

      stim_1st = answer.response.comparable_answer_or_nil_for_question_with_code('STIM_1ST')
      opu_date = answer.response.comparable_answer_or_nil_for_question_with_code('OPU_DATE')
      can_date = answer.response.comparable_answer_or_nil_for_question_with_code('CAN_DATE')

      break true if stim_1st != 'y'
      stim_1st == 'y' && (!opu_date.nil? || !can_date.nil?)
    }

    CrossQuestionValidation.register_checker 'special_rule_pgt_2', lambda { |answer, ununused_related_answer, checker_params|
      # special_rule_pgt_2: n_pgt_assay + n_pgt_th>=n_pgt_et
      raise 'Can only be used on question N_PGT_ET' unless answer.question.code == 'N_PGT_ET'

      n_pgt_th = answer_or_0_if_nil answer.response.comparable_answer_or_nil_for_question_with_code('N_PGT_TH')
      n_pgt_assay = answer_or_0_if_nil answer.response.comparable_answer_or_nil_for_question_with_code('N_PGT_ASSAY')
      n_pgt_et = answer_or_0_if_nil answer.response.comparable_answer_or_nil_for_question_with_code('N_PGT_ET')

      (n_pgt_assay + n_pgt_th) >= n_pgt_et
    }

    CrossQuestionValidation.register_checker 'special_rule_pgt_3', lambda { |answer, ununused_related_answer, checker_params|
      # special_rule_pgt_3: n_s_clth + n_v_clth + n_s_blth + n_v_blth>=n_pgt_th
      raise 'Can only be used on question N_PGT_TH' unless answer.question.code == 'N_PGT_TH'

      n_s_clth = answer_or_0_if_nil answer.response.comparable_answer_or_nil_for_question_with_code('N_S_CLTH')
      n_v_clth = answer_or_0_if_nil answer.response.comparable_answer_or_nil_for_question_with_code('N_V_CLTH')
      n_s_blth = answer_or_0_if_nil answer.response.comparable_answer_or_nil_for_question_with_code('N_S_BLTH')
      n_v_blth = answer_or_0_if_nil answer.response.comparable_answer_or_nil_for_question_with_code('N_V_BLTH')
      n_pgt_th = answer_or_0_if_nil answer.response.comparable_answer_or_nil_for_question_with_code('N_PGT_TH')

      (n_s_clth + n_v_clth + n_s_blth + n_v_blth) >= n_pgt_th
    }

    CrossQuestionValidation.register_checker 'special_rule_surr_2', lambda { |answer, ununused_related_answer, checker_params|
      # special_rule_surr_2: if cycle_type = 7, then n_embrec_fresh + n_s_clth + n_v_clth + n_s_blth + n_v_blth >0
      raise 'Can only be used on question CYCLE_TYPE' unless answer.question.code == 'CYCLE_TYPE'

      cycle_type = answer.response.comparable_answer_or_nil_for_question_with_code('CYCLE_TYPE')
      n_embrec_fresh = answer_or_0_if_nil answer.response.comparable_answer_or_nil_for_question_with_code('N_EMBREC_FRESH')
      n_s_clth = answer_or_0_if_nil answer.response.comparable_answer_or_nil_for_question_with_code('N_S_CLTH')
      n_v_clth = answer_or_0_if_nil answer.response.comparable_answer_or_nil_for_question_with_code('N_V_CLTH')
      n_s_blth = answer_or_0_if_nil answer.response.comparable_answer_or_nil_for_question_with_code('N_S_BLTH')
      n_v_blth = answer_or_0_if_nil answer.response.comparable_answer_or_nil_for_question_with_code('N_V_BLTH')

      break true unless cycle_type == '7'
      (n_embrec_fresh + n_s_clth + n_v_clth + n_s_blth + n_v_blth) > 0
    }

    CrossQuestionValidation.register_checker 'special_rule_surr_3', lambda { |answer, ununused_related_answer, checker_params|
      # special_rule_surr_3: if surr=y & cycle_type!= 7, then et_date = NULL & (n_bl_et+n_cl_et)=0
      raise 'Can only be used on question SURR' unless answer.question.code == 'SURR'

      surr = answer.response.comparable_answer_or_nil_for_question_with_code('SURR')
      cycle_type = answer.response.comparable_answer_or_nil_for_question_with_code('CYCLE_TYPE')
      et_date = answer.response.comparable_answer_or_nil_for_question_with_code('ET_DATE')
      n_bl_et = answer_or_0_if_nil answer.response.comparable_answer_or_nil_for_question_with_code('N_BL_ET')
      n_cl_et = answer_or_0_if_nil answer.response.comparable_answer_or_nil_for_question_with_code('N_CL_ET')

      break true unless surr == 'y' && cycle_type != '7'
      et_date.nil? && (n_bl_et + n_cl_et) == 0
    }

    CrossQuestionValidation.register_checker 'special_rule_surr_4', lambda { |answer, ununused_related_answer, checker_params|
      # special_rule_surr_4: if surr = "n" & fdob_non_pat!=NULL, then PARENT_SEX = 3
      raise 'Can only be used on question SURR' unless answer.question.code == 'SURR'

      surr = answer.response.comparable_answer_or_nil_for_question_with_code('SURR')
      fdob_non_pat = answer.response.comparable_answer_or_nil_for_question_with_code('FDOB_NON_PAT')
      parent_sex = answer.response.comparable_answer_or_nil_for_question_with_code('PARENT_SEX')

      break true unless surr == 'n' && !fdob_non_pat.nil?
      parent_sex == '3'
    }

    CrossQuestionValidation.register_checker 'special_rule_surr_5', lambda { |answer, ununused_related_answer, checker_params|
      # special_rule_surr_5: if surr = "y" & fdob_non_pat!=NULL, then PARENT_SEX = 1,2 or 3 & CYCLE_TYPE = 6
      raise 'Can only be used on question SURR' unless answer.question.code == 'SURR'

      surr = answer.response.comparable_answer_or_nil_for_question_with_code('SURR')
      fdob_non_pat = answer.response.comparable_answer_or_nil_for_question_with_code('FDOB_NON_PAT')
      parent_sex = answer.response.comparable_answer_or_nil_for_question_with_code('PARENT_SEX')
      cycle_type = answer.response.comparable_answer_or_nil_for_question_with_code('CYCLE_TYPE')

      break true unless surr == 'y' && !fdob_non_pat.nil?
      ['1', '2', '3'].include?(parent_sex) && cycle_type == '6'
    }

    CrossQuestionValidation.register_checker 'special_rule_cycletype_2_don', lambda { |answer, ununused_related_answer, checker_params|
      # special_rule_cycletype_2_don: if cycle_type = 2 & n_eggrec_fresh=0 & n_s_egth=0 & n_v_egth=0, then (one of n_eggdon_fresh or n_egfz_s or n_egfz_v >0)
      raise 'Can only be used on question CYCLE_TYPE' unless answer.question.code == 'CYCLE_TYPE'

      cycle_type = answer.response.comparable_answer_or_nil_for_question_with_code('CYCLE_TYPE')
      n_eggrec_fresh = answer.response.comparable_answer_or_nil_for_question_with_code('N_EGGREC_FRESH')
      n_s_egth = answer.response.comparable_answer_or_nil_for_question_with_code('N_S_EGTH')
      n_v_egth = answer.response.comparable_answer_or_nil_for_question_with_code('N_V_EGTH')
      n_eggdon_fresh = answer_or_0_if_nil answer.response.comparable_answer_or_nil_for_question_with_code('N_EGGDON_FRESH')
      n_egfz_s = answer_or_0_if_nil answer.response.comparable_answer_or_nil_for_question_with_code('N_EGFZ_S')
      n_egfz_v = answer_or_0_if_nil answer.response.comparable_answer_or_nil_for_question_with_code('N_EGFZ_V')

      break true unless cycle_type == '2' && n_eggrec_fresh == 0 && n_s_egth == 0 && n_v_egth == 0
      n_eggdon_fresh > 0 || n_egfz_s > 0 || n_egfz_v > 0
    }

    CrossQuestionValidation.register_checker 'special_rule_cycletype_2_rec', lambda { |answer, ununused_related_answer, checker_params|
      # special_rule_cycletype_2_rec: if cycle_type = 2 & n_eggdon_fresh=0 & n_efgz_s=0 & n_egfz_v=0, then  (one of n_eggrec_fresh or n_s_egth or n_v_egth >0)
      raise 'Can only be used on question CYCLE_TYPE' unless answer.question.code == 'CYCLE_TYPE'

      cycle_type = answer.response.comparable_answer_or_nil_for_question_with_code('CYCLE_TYPE')
      n_eggdon_fresh = answer.response.comparable_answer_or_nil_for_question_with_code('N_EGGDON_FRESH')
      n_efgz_s = answer.response.comparable_answer_or_nil_for_question_with_code('N_EFGZ_S')
      n_egfz_v = answer.response.comparable_answer_or_nil_for_question_with_code('N_EGFZ_V')
      n_eggrec_fresh = answer_or_0_if_nil answer.response.comparable_answer_or_nil_for_question_with_code('N_EGGREC_FRESH')
      n_s_egth = answer_or_0_if_nil answer.response.comparable_answer_or_nil_for_question_with_code('N_S_EGTH')
      n_v_egth = answer_or_0_if_nil answer.response.comparable_answer_or_nil_for_question_with_code('N_V_EGTH')

      break true unless cycle_type == 2 && n_eggdon_fresh == 0 && n_efgz_s == 0 && n_egfz_v == 0
      n_eggrec_fresh > 0 || n_s_egth > 0 || n_v_egth > 0
    }

    CrossQuestionValidation.register_checker 'special_rule_ttc', lambda { |answer, ununused_related_answer, checker_params|
      # special_rule_ttc: if parent_sex = 1 and stim_1st =y, then date_ttc must be complete
      raise 'Can only be used on question PARENT_SEX' unless answer.question.code == 'PARENT_SEX'

      parent_sex = answer.response.comparable_answer_or_nil_for_question_with_code('PARENT_SEX')
      stim_1st = answer.response.comparable_answer_or_nil_for_question_with_code('STIM_1ST')
      date_ttc = answer.response.comparable_answer_or_nil_for_question_with_code('DATE_TTC')

      break true unless parent_sex == 1 && stim_1st == 'y'
      !date_ttc.nil?
    }
  end

  private

  def self.age_in_completed_years (date_of_birth, other_date)
    # Difference in years, less one if you have not had a birthday this year (accounts for leap years).
    age = other_date.year - date_of_birth.year
    age = age - 1 if (date_of_birth.month > other_date.month or (date_of_birth.month >= other_date.month and date_of_birth.day > other_date.day))
    age
  end

  def self.answer_or_0_if_nil (answer)
    result = 0
    result = answer if !answer.nil?
    result
  end
end