require 'rails_helper'


describe "Special Rules" do
  pending "shouldn't call 'present' on an answer" do
    survey = create(:survey)
    section = create(:section, survey: survey)
    response = create(:response, survey: survey)
    o2_36wk = create(:question, section: section, code: 'O2_36wk_', question_type: Question::TYPE_INTEGER)
    gest = create(:question, section: section, code: SpecialRules::GEST_CODE, question_type: Question::TYPE_INTEGER)
    wght = create(:question, section: section, code: SpecialRules::WGHT_CODE, question_type: Question::TYPE_INTEGER)

    survey.send(:populate_question_hash)

    cqv = create(:cross_question_validation, rule: 'special_o2_a', related_question: nil, question: o2_36wk, error_message: 'If O2_36wk_ is -1 and (Gest must be <32 or Wght must be <1500) then (Gest+Gestdays + weeks(DOB and the latest date of (LastO2|CeaseCPAPDate|CeaseHiFloDate))) >36')

    gest_answer = create(:answer, question: gest, response: @response, answer_value: CrossQuestionValidation::GEST_LT - 1)
    a = create(:answer, question: o2_36wk, response: @response, answer_value: '-1')
    raise "#{a.response.answers.inspect} #{a.response.answers.count}" # gives "[] 2" ????

    warnings = CrossQuestionValidation.check(a)
    warnings.should be_present
  end

  describe "RULE: special_cool_hours" do
    #hours between |CeaseCoolDate+CeaseCoolTime - StartCoolDate+StartCoolTime| should not be greater than 120 hours
    before(:each) do
      @survey = create(:survey)
      @section = create(:section, survey: @survey)
      @start_cool_date = create(:question, code: 'StartCoolDate', section: @section, question_type: Question::TYPE_DATE)
      @start_cool_time = create(:question, code: 'StartCoolTime', section: @section, question_type: Question::TYPE_TIME)
      @cease_cool_date = create(:question, code: 'CeaseCoolDate', section: @section, question_type: Question::TYPE_DATE)
      @cease_cool_time = create(:question, code: 'CeaseCoolTime', section: @section, question_type: Question::TYPE_TIME)
      @cqv = create(:cross_question_validation, rule: 'special_cool_hours', question: @start_cool_date, error_message: 'My message', related_question_id: nil)
      @response = create(:response, survey: @survey)
    end

    it 'should raise an error if used on the wrong question' do
      q = create(:question, code: 'Blah')
      cqv = build(:cross_question_validation, rule: 'special_cool_hours', question: q)
      cqv.valid?.should be false
      cqv.errors[:base].should eq ['special_cool_hours requires question code StartCoolDate but got Blah']
    end

    describe 'should fail when hour difference is > 120' do
      it 'over by 1 minute' do
        cool_hours_test('2013-05-01', '11:59', '2013-05-06', '12:00', 'My message')
      end
      it 'over by a lot' do
        cool_hours_test('2013-05-01', '11:59', '2013-06-04', '12:00', 'My message')
      end
    end

    it 'should pass when hour difference is = 72' do
      cool_hours_test('2013-05-01', '11:59', '2013-05-06', '11:59', nil)
    end

    describe 'should pass when hour difference is < 72' do
      it 'under by 1 minute' do
        cool_hours_test('2013-05-01', '11:59', '2013-05-06', '11:58', nil)
      end
      it 'under by a lot' do
        cool_hours_test('2013-05-01', '11:59', '2013-05-02', '11:59', nil)
      end
    end

    describe 'should pass if all 4 questions not answered' do
      it {cool_hours_test('2013-05-01', nil, '2013-06-04', '12:00', nil)}
      it {cool_hours_test('2013-05-01', '11:59', nil, '12:00', nil)}
      it {cool_hours_test('2013-05-01', '11:59', '2013-06-04', nil, nil)}
    end

    def cool_hours_test(start_date, start_time, cease_date, cease_time, outcome)
      answer = create(:answer, question: @start_cool_date, answer_value: start_date, response: @response)
      create(:answer, question: @start_cool_time, answer_value: start_time, response: @response) unless start_time.nil?
      create(:answer, question: @cease_cool_date, answer_value: cease_date, response: @response) unless cease_date.nil?
      create(:answer, question: @cease_cool_time, answer_value: cease_time, response: @response) unless cease_time.nil?
      answer.reload
      @cqv.check(answer).should eq(outcome)
    end

  end

  describe "RULE: special_o2_a" do
    #If O2_36wk_ is -1 and (Gest must be <32 or Wght must be <1500) and (Gest+Gestdays + weeks(DOB and the latest date of (LastO2|CeaseCPAPDate|CeaseHiFloDate))) >36
    before(:each) do
      @survey = create(:survey)
      @section = create(:section, survey: @survey)
      @o2_36_wk = create(:question, code: 'O2_36wk_', section: @section, question_type: Question::TYPE_CHOICE)
      create(:question_option, question: @o2_36_wk, option_value: 99)
      create(:question_option, question: @o2_36_wk, option_value: 0)
      create(:question_option, question: @o2_36_wk, option_value: -1)
      @gest = create(:question, code: 'Gest', section: @section, question_type: Question::TYPE_INTEGER)
      @gest_days = create(:question, code: 'Gestdays', section: @section, question_type: Question::TYPE_INTEGER)
      @dob = create(:question, code: 'DOB', section: @section, question_type: Question::TYPE_DATE)
      @last_o2 = create(:question, code: 'LastO2', section: @section, question_type: Question::TYPE_DATE)
      @cease_cpap = create(:question, code: 'CeaseCPAPDate', section: @section, question_type: Question::TYPE_DATE)
      @cease_hiflo = create(:question, code: 'CeaseHiFloDate', section: @section, question_type: Question::TYPE_DATE)
      @cqv = create(:cross_question_validation, rule: 'special_o2_a', question: @o2_36_wk, error_message: 'My message', related_question_id: nil)
      @response = create(:response, survey: @survey)
    end

    it 'should raise an error if used on the wrong question' do
      q = create(:question, code: 'Blah')
      cqv = build(:cross_question_validation, rule: 'special_o2_a', question: q)
      cqv.valid?.should be false
      cqv.errors[:base].should eq ['special_o2_a requires question code O2_36wk_ but got Blah']
    end

    it 'should pass when O2_36wk_ is anything other than -1' do
      [0, 99].each do |answer_val|
        answer = create(:answer, question: @o2_36_wk, answer_value: answer_val, response: @response)
        @cqv.check(answer).should be_nil
      end
    end

    describe 'when O2_36wk_ is -1' do
      it 'should pass when not premature' do
        # logic for "Gest must be <32 or Wght must be <1500" is tested separately, so mock that part to simplify testing here
        CrossQuestionValidation.should_receive(:check_gest_wght).and_return(false)
        answer = create(:answer, question: @o2_36_wk, answer_value: -1, response: @response)
        @cqv.check(answer).should be_nil
      end

      describe 'When premature' do
        it 'should fail when any of Gest, Gestdays, DOB are not answered' do
          # TODO: clarify that fail is correct here, unclear from description
          # logic for Gest must be <32 or Wght must be <1500 is tested separately, so mock that part to simplify testing here
          CrossQuestionValidation.should_receive(:check_gest_wght).exactly(3).times.and_return(true)
          answer = create(:answer, question: @o2_36_wk, answer_value: -1, response: @response)
          create(:answer, question: @gest, answer_value: '38', response: @response)
          create(:answer, question: @gest_days, answer_value: '5', response: @response)
          create(:answer, question: @dob, answer_value: '2013-01-01', response: @response)
          answer.reload
          [@gest, @gest_days, @dob].each do |q|
            answer.response.answers.where(question_id: q.id).destroy_all
            @cqv.check(answer).should eq("My message")
          end
        end

        it 'should fail when none of LastO2, CeaseCPAPDate, CeaseHiFloDate are answered' do
          # logic for Gest must be <32 or Wght must be <1500 is tested separately, so mock that part to simplify testing here
          # TODO: clarify that fail is correct here, unclear from description
          CrossQuestionValidation.should_receive(:check_gest_wght).and_return(true)
          answer = create(:answer, question: @o2_36_wk, answer_value: -1, response: @response)
          create(:answer, question: @gest, answer_value: '38', response: @response)
          create(:answer, question: @gest_days, answer_value: '5', response: @response)
          create(:answer, question: @dob, answer_value: '2013-01-01', response: @response)
          answer.reload
          @cqv.check(answer).should eq("My message")
        end

        # testing and (Gest+Gestdays + weeks(DOB and the latest date of (LastO2|CeaseCPAPDate|CeaseHiFloDate))) >36
        describe 'date calculations' do
          # 36 weeks = 252 days
          it 'should pass when total > 36' do
            CrossQuestionValidation.should_receive(:check_gest_wght).and_return(true)
            answer = create(:answer, question: @o2_36_wk, answer_value: -1, response: @response)
            create(:answer, question: @gest, answer_value: '33', response: @response) # 231
            create(:answer, question: @gest_days, answer_value: '2', response: @response) # 2
            create(:answer, question: @dob, answer_value: '2013-01-01', response: @response)
            create(:answer, question: @cease_cpap, answer_value: '2013-01-21', response: @response) # 20 d diff
            answer.reload
            @cqv.check(answer).should be_nil
          end

          it 'should fail when total = 36' do
            CrossQuestionValidation.should_receive(:check_gest_wght).and_return(true)
            answer = create(:answer, question: @o2_36_wk, answer_value: -1, response: @response)
            create(:answer, question: @gest, answer_value: '33', response: @response) # 231
            create(:answer, question: @gest_days, answer_value: '2', response: @response) # 2
            create(:answer, question: @dob, answer_value: '2013-01-01', response: @response)
            create(:answer, question: @cease_cpap, answer_value: '2013-01-20', response: @response) # 19 d diff
            answer.reload
            @cqv.check(answer).should eq('My message')
          end

          it 'should fail when total < 36' do
            CrossQuestionValidation.should_receive(:check_gest_wght).and_return(true)
            answer = create(:answer, question: @o2_36_wk, answer_value: -1, response: @response)
            create(:answer, question: @gest, answer_value: '33', response: @response) # 231
            create(:answer, question: @gest_days, answer_value: '2', response: @response) # 2
            create(:answer, question: @dob, answer_value: '2013-01-01', response: @response)
            create(:answer, question: @cease_cpap, answer_value: '2013-01-19', response: @response) # 18 d diff
            answer.reload
            @cqv.check(answer).should eq('My message')
          end

          it 'with different question as latest date' do
            CrossQuestionValidation.should_receive(:check_gest_wght).and_return(true)
            answer = create(:answer, question: @o2_36_wk, answer_value: -1, response: @response)
            create(:answer, question: @gest, answer_value: '33', response: @response) # 231
            create(:answer, question: @gest_days, answer_value: '2', response: @response) # 2
            create(:answer, question: @dob, answer_value: '2013-01-01', response: @response)

            create(:answer, question: @cease_cpap, answer_value: '2013-01-10', response: @response)
            create(:answer, question: @cease_hiflo, answer_value: '2013-01-19', response: @response)
            create(:answer, question: @last_o2, answer_value: '2013-01-21', response: @response) # 18 d diff
            answer.reload
            @cqv.check(answer).should be_nil
          end
        end
      end
    end
  end

  describe "RULE: special_hmeo2" do
    # If HmeO2 is -1 and (Gest must be <32 or Wght must be <1500) and HomeDate must be a date and HomeDate must be the same as LastO2
    before(:each) do
      @survey = create(:survey)
      @section = create(:section, survey: @survey)
      @hme_o2 = create(:question, code: 'HmeO2', section: @section, question_type: Question::TYPE_CHOICE)
      create(:question_option, question: @hme_o2, option_value: 99)
      create(:question_option, question: @hme_o2, option_value: 0)
      create(:question_option, question: @hme_o2, option_value: -1)
      @gest = create(:question, code: 'Gest', section: @section, question_type: Question::TYPE_INTEGER)
      @gest_days = create(:question, code: 'Gestdays', section: @section, question_type: Question::TYPE_INTEGER)
      @home_date = create(:question, code: 'HomeDate', section: @section, question_type: Question::TYPE_DATE)
      @last_o2 = create(:question, code: 'LastO2', section: @section, question_type: Question::TYPE_DATE)
      @cqv = create(:cross_question_validation, rule: 'special_hmeo2', question: @hme_o2, error_message: 'My message', related_question_id: nil)
      @response = create(:response, survey: @survey)
    end

    it 'should raise an error if used on the wrong question' do
      q = create(:question, code: 'Blah')
      cqv = build(:cross_question_validation, rule: 'special_hmeo2', question: q)
      cqv.valid?.should be false
      cqv.errors[:base].should eq ['special_hmeo2 requires question code HmeO2 but got Blah']
    end

    it 'should pass when HmeO2 is anything other than -1' do
      [0, 99].each do |answer_val|
        answer = create(:answer, question: @hme_o2, answer_value: answer_val, response: @response)
        @cqv.check(answer).should be_nil
      end
    end

    describe 'when HmeO2 is -1' do
      it 'should pass when not premature' do
        # logic for "Gest must be <32 or Wght must be <1500" is tested separately, so mock that part to simplify testing here
        CrossQuestionValidation.should_receive(:check_gest_wght).and_return(false)
        answer = create(:answer, question: @hme_o2, answer_value: -1, response: @response)
        @cqv.check(answer).should be_nil
      end

      describe 'When premature' do
        it 'should fail when HomeDate not answered' do
          # logic for "Gest must be <32 or Wght must be <1500" is tested separately, so mock that part to simplify testing here
          CrossQuestionValidation.should_receive(:check_gest_wght).and_return(true)
          answer = create(:answer, question: @hme_o2, answer_value: -1, response: @response)
          @cqv.check(answer).should eq('My message')
        end

        it 'should fail when HomeDate answered but LastO2 not answered' do
          # logic for "Gest must be <32 or Wght must be <1500" is tested separately, so mock that part to simplify testing here
          CrossQuestionValidation.should_receive(:check_gest_wght).and_return(true)
          answer = create(:answer, question: @hme_o2, answer_value: -1, response: @response)
          create(:answer, question: @home_date, answer_value: '2013-01-01', response: @response)
          answer.reload
          @cqv.check(answer).should eq('My message')
        end

        it 'should pass when HomeDate and LastO2 are the same' do
          CrossQuestionValidation.should_receive(:check_gest_wght).and_return(true)
          answer = create(:answer, question: @hme_o2, answer_value: -1, response: @response)
          create(:answer, question: @home_date, answer_value: '2013-01-01', response: @response)
          create(:answer, question: @last_o2, answer_value: '2013-01-01', response: @response)
          answer.reload
          @cqv.check(answer).should be_nil
        end

        it 'should fail when HomeDate before LastO2' do
          CrossQuestionValidation.should_receive(:check_gest_wght).and_return(true)
          answer = create(:answer, question: @hme_o2, answer_value: -1, response: @response)
          create(:answer, question: @home_date, answer_value: '2013-01-01', response: @response)
          create(:answer, question: @last_o2, answer_value: '2013-01-02', response: @response)
          answer.reload
          @cqv.check(answer).should eq('My message')
        end

        it 'should fail when HomeDate after LastO2' do
          CrossQuestionValidation.should_receive(:check_gest_wght).and_return(true)
          answer = create(:answer, question: @hme_o2, answer_value: -1, response: @response)
          create(:answer, question: @home_date, answer_value: '2013-01-02', response: @response)
          create(:answer, question: @last_o2, answer_value: '2013-01-01', response: @response)
          answer.reload
          @cqv.check(answer).should eq('My message')
        end
      end
    end
  end

  describe "RULE: special_o2_a_new" do
    # this rule is separate to special_o2_a so that we can maintain backward compatibility with old surveys
    #If O2_36wk_ is -1 and (Gest must be <32 or Wght must be <1500) then (Gest+Gestdays + weeks(DOB and the latest date of (LastRespSupp|CeaseCPAPDate|CeaseHiFloDate))) >35
    before(:each) do
      @survey = create(:survey)
      @section = create(:section, survey: @survey)
      @o2_36_wk = create(:question, code: 'O2_36wk_', section: @section, question_type: Question::TYPE_CHOICE)
      create(:question_option, question: @o2_36_wk, option_value: 99)
      create(:question_option, question: @o2_36_wk, option_value: 0)
      create(:question_option, question: @o2_36_wk, option_value: -1)
      @gest = create(:question, code: 'Gest', section: @section, question_type: Question::TYPE_INTEGER)
      @gest_days = create(:question, code: 'Gestdays', section: @section, question_type: Question::TYPE_INTEGER)
      @dob = create(:question, code: 'DOB', section: @section, question_type: Question::TYPE_DATE)
      @last_resp_supp = create(:question, code: 'LastRespSupp', section: @section, question_type: Question::TYPE_DATE)
      @cease_cpap = create(:question, code: 'CeaseCPAPDate', section: @section, question_type: Question::TYPE_DATE)
      @cease_hiflo = create(:question, code: 'CeaseHiFloDate', section: @section, question_type: Question::TYPE_DATE)
      @cqv = create(:cross_question_validation, rule: 'special_o2_a_new', question: @o2_36_wk, error_message: 'My message', related_question_id: nil)
      @response = create(:response, survey: @survey)
    end

    it 'should raise an error if used on the wrong question' do
      q = create(:question, code: 'Blah')
      cqv = build(:cross_question_validation, rule: 'special_o2_a_new', question: q)
      cqv.valid?.should be false
      cqv.errors[:base].should eq ['special_o2_a_new requires question code O2_36wk_ but got Blah']
    end

    it 'should pass when O2_36wk_ is anything other than -1' do
      [0, 99].each do |answer_val|
        answer = create(:answer, question: @o2_36_wk, answer_value: answer_val, response: @response)
        @cqv.check(answer).should be_nil
      end
    end

    describe 'when O2_36wk_ is -1' do
      it 'should pass when not premature' do
        # logic for "Gest must be <32 or Wght must be <1500" is tested separately, so mock that part to simplify testing here
        CrossQuestionValidation.should_receive(:check_gest_wght).and_return(false)
        answer = create(:answer, question: @o2_36_wk, answer_value: -1, response: @response)
        @cqv.check(answer).should be_nil
      end

      describe 'When premature' do
        it 'should pass when any of Gest, Gestdays, DOB are not answered' do
          # Gest, Gestdays, DOB are mandatory anyway so will already generate errors, therefore we let this rule pass to avoid excessive messages
          # logic for Gest must be <32 or Wght must be <1500 is tested separately, so mock that part to simplify testing here
          CrossQuestionValidation.should_receive(:check_gest_wght).exactly(3).times.and_return(true)
          answer = create(:answer, question: @o2_36_wk, answer_value: -1, response: @response)
          create(:answer, question: @gest, answer_value: '38', response: @response)
          create(:answer, question: @gest_days, answer_value: '5', response: @response)
          create(:answer, question: @dob, answer_value: '2013-01-01', response: @response)
          answer.reload
          [@gest, @gest_days, @dob].each do |q|
            answer.response.answers.where(question_id: q.id).destroy_all
            @cqv.check(answer).should be_nil
          end
        end

        it 'should pass when none of LastRespSupp, CeaseCPAPDate, CeaseHiFloDate are answered' do
          # logic for Gest must be <32 or Wght must be <1500 is tested separately, so mock that part to simplify testing here
          # TODO: clarify that fail is correct here, unclear from description
          CrossQuestionValidation.should_receive(:check_gest_wght).and_return(true)
          answer = create(:answer, question: @o2_36_wk, answer_value: -1, response: @response)
          create(:answer, question: @gest, answer_value: '38', response: @response)
          create(:answer, question: @gest_days, answer_value: '5', response: @response)
          create(:answer, question: @dob, answer_value: '2013-01-01', response: @response)
          answer.reload
          @cqv.check(answer).should be_nil
        end

        # testing and (Gest+Gestdays + weeks(DOB and the latest date of (LastRespSupp|CeaseCPAPDate|CeaseHiFloDate))) >36
        describe 'date calculations' do
          # 35 weeks = 245 days
          it 'should pass when total > 35' do
            CrossQuestionValidation.should_receive(:check_gest_wght).and_return(true)
            answer = create(:answer, question: @o2_36_wk, answer_value: -1, response: @response)
            create(:answer, question: @gest, answer_value: '33', response: @response) # 231
            create(:answer, question: @gest_days, answer_value: '2', response: @response) # 2
            create(:answer, question: @dob, answer_value: '2013-01-01', response: @response)
            create(:answer, question: @cease_cpap, answer_value: '2013-01-14', response: @response) # 13 d diff
            answer.reload
            @cqv.check(answer).should be_nil
          end

          it 'should fail when total = 35' do
            CrossQuestionValidation.should_receive(:check_gest_wght).and_return(true)
            answer = create(:answer, question: @o2_36_wk, answer_value: -1, response: @response)
            create(:answer, question: @gest, answer_value: '33', response: @response) # 231
            create(:answer, question: @gest_days, answer_value: '2', response: @response) # 2
            create(:answer, question: @dob, answer_value: '2013-01-01', response: @response)
            create(:answer, question: @cease_cpap, answer_value: '2013-01-13', response: @response) # 12 d diff
            answer.reload
            @cqv.check(answer).should eq('My message')
          end

          it 'should fail when total < 35' do
            CrossQuestionValidation.should_receive(:check_gest_wght).and_return(true)
            answer = create(:answer, question: @o2_36_wk, answer_value: -1, response: @response)
            create(:answer, question: @gest, answer_value: '33', response: @response) # 231
            create(:answer, question: @gest_days, answer_value: '2', response: @response) # 2
            create(:answer, question: @dob, answer_value: '2013-01-01', response: @response)
            create(:answer, question: @cease_cpap, answer_value: '2013-01-12', response: @response) # 11 d diff
            answer.reload
            @cqv.check(answer).should eq('My message')
          end

          it 'with different question as latest date' do
            CrossQuestionValidation.should_receive(:check_gest_wght).and_return(true)
            answer = create(:answer, question: @o2_36_wk, answer_value: -1, response: @response)
            create(:answer, question: @gest, answer_value: '33', response: @response) # 231
            create(:answer, question: @gest_days, answer_value: '2', response: @response) # 2
            create(:answer, question: @dob, answer_value: '2013-01-01', response: @response)

            create(:answer, question: @cease_cpap, answer_value: '2013-01-10', response: @response)
            create(:answer, question: @cease_hiflo, answer_value: '2013-01-19', response: @response)
            create(:answer, question: @last_resp_supp, answer_value: '2013-01-14', response: @response) # 13 d diff
            answer.reload
            @cqv.check(answer).should be_nil
          end
        end
      end
    end
  end

  describe "RULE: special_hmeo2_new" do
    # If HmeO2 is -1 and HomeDate is a date then HomeDate must be the same as LastRespSupp
    before(:each) do
      @survey = create(:survey)
      @section = create(:section, survey: @survey)
      @hme_o2 = create(:question, code: 'HmeO2', section: @section, question_type: Question::TYPE_CHOICE)
      create(:question_option, question: @hme_o2, option_value: 99)
      create(:question_option, question: @hme_o2, option_value: 0)
      create(:question_option, question: @hme_o2, option_value: -1)
      @home_date = create(:question, code: 'HomeDate', section: @section, question_type: Question::TYPE_DATE)
      @last_resp_supp = create(:question, code: 'LastRespSupp', section: @section, question_type: Question::TYPE_DATE)
      @cqv = create(:cross_question_validation, rule: 'special_hmeo2_new', question: @hme_o2, error_message: 'My message', related_question_id: nil)
      @response = create(:response, survey: @survey)
    end

    it 'should raise an error if used on the wrong question' do
      q = create(:question, code: 'Blah')
      cqv = build(:cross_question_validation, rule: 'special_hmeo2_new', question: q)
      cqv.valid?.should be false
      cqv.errors[:base].should eq ['special_hmeo2_new requires question code HmeO2 but got Blah']
    end

    it 'should pass when HmeO2 is anything other than -1' do
      [0, 99].each do |answer_val|
        answer = create(:answer, question: @hme_o2, answer_value: answer_val, response: @response)
        @cqv.check(answer).should be_nil
      end
    end

    describe 'when HmeO2 is -1' do
      it 'should pass when HomeDate not answered' do
        answer = create(:answer, question: @hme_o2, answer_value: -1, response: @response)
        @cqv.check(answer).should be_nil
      end

      it 'should fail when HomeDate answered but LastRespSupp not answered' do
        answer = create(:answer, question: @hme_o2, answer_value: -1, response: @response)
        create(:answer, question: @home_date, answer_value: '2013-01-01', response: @response)
        answer.reload
        @cqv.check(answer).should eq('My message')
      end

      it 'should pass when HomeDate and LastRespSupp are the same' do
        answer = create(:answer, question: @hme_o2, answer_value: -1, response: @response)
        create(:answer, question: @home_date, answer_value: '2013-01-01', response: @response)
        create(:answer, question: @last_resp_supp, answer_value: '2013-01-01', response: @response)
        answer.reload
        @cqv.check(answer).should be_nil
      end

      it 'should fail when HomeDate before LastRespSupp' do
        answer = create(:answer, question: @hme_o2, answer_value: -1, response: @response)
        create(:answer, question: @home_date, answer_value: '2013-01-01', response: @response)
        create(:answer, question: @last_resp_supp, answer_value: '2013-01-02', response: @response)
        answer.reload
        @cqv.check(answer).should eq('My message')
      end

      it 'should fail when HomeDate after LastO2' do
        answer = create(:answer, question: @hme_o2, answer_value: -1, response: @response)
        create(:answer, question: @home_date, answer_value: '2013-01-02', response: @response)
        create(:answer, question: @last_resp_supp, answer_value: '2013-01-01', response: @response)
        answer.reload
        @cqv.check(answer).should eq('My message')
      end
    end
  end

  describe "RULE: rule22d" do
    # rule22d: n_v_egth + n_s_egth + n_eggs + n_recvd >= n_donate + n_ivf + n_icsi + n_egfz_s + n_egfz_v
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
      @cqv = create(:cross_question_validation, rule: 'special_rule_22_d', question: @n_v_egth, error_message: 'My error message', related_question_id: nil)
      @response = create(:response, survey: @survey)
    end

    it 'should raise an error if used on the wrong question' do
      q = create(:question, code: 'Blah')
      cqv = build(:cross_question_validation, rule: 'special_rule_22_d', question: q)
      expect(cqv.valid?).to be false
      expect(cqv.errors[:base]).to eq ['special_rule_22_d requires question code N_V_EGTH but got Blah']
    end

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

  describe "RULE: rule17_a" do
    # rule17a: if pr_clin is y or u, n_bl_et>0 |n_cl_et >0 | iui_date is a date
    before(:each) do
      @survey = create(:survey)
      @section = create(:section, survey: @survey)
      @pr_clin = create(:question, code: 'PR_CLIN', section: @section, question_type: Question::TYPE_CHOICE)
      @n_bl_et = create(:question, code: 'N_BL_ET', section: @section, question_type: Question::TYPE_INTEGER)
      @n_cl_et = create(:question, code: 'N_CL_ET', section: @section, question_type: Question::TYPE_INTEGER)
      @iui_date = create(:question, code: 'IUI_DATE', section: @section, question_type: Question::TYPE_DATE)
      @cqv = create(:cross_question_validation, rule: 'special_rule_17_a', question: @pr_clin, error_message: 'My error message', related_question_id: nil)
      @response = create(:response, survey: @survey)
    end

    it 'should raise an error if used on the wrong question' do
      q = create(:question, code: 'Blah')
      cqv = build(:cross_question_validation, rule: 'special_rule_17_a', question: q)
      expect(cqv.valid?).to be false
      expect(cqv.errors[:base]).to eq ['special_rule_17_a requires question code PR_CLIN but got Blah']
    end

    it 'should pass when pr_clin is not y or u and neither n_bl_et > 0 or n_cl_et > 0 or iui_date is a date' do
      answer = create(:answer, question: @pr_clin, answer_value: 'n', response: @response)
      create(:answer, question: @n_bl_et, answer_value: -1, response: @response)
      create(:answer, question: @n_cl_et, answer_value: -1, response: @response)
      # no answer object created for iui_date to represent it not being answered
      answer.reload
      expect(@cqv.check(answer)).to be_nil
    end

    ['y', 'u'].each do |pr_clin_trigger_value|
      it "should fail when pr_clin is #{pr_clin_trigger_value} and neither n_bl_et > 0 or n_cl_et > 0 or iui_date is a date" do
        answer = create(:answer, question: @pr_clin, answer_value: pr_clin_trigger_value, response: @response)
        create(:answer, question: @n_bl_et, answer_value: -1, response: @response)
        create(:answer, question: @n_cl_et, answer_value: -1, response: @response)
        # no answer object created for iui_date to represent it not being answered
        answer.reload
        expect(@cqv.check(answer)).to eq('My error message')
      end

      it "should pass when pr_clin is #{pr_clin_trigger_value} and n_bl_et > 0" do
        answer = create(:answer, question: @pr_clin, answer_value: pr_clin_trigger_value, response: @response)
        create(:answer, question: @n_bl_et, answer_value: 1, response: @response)
        create(:answer, question: @n_cl_et, answer_value: -1, response: @response)
        # no answer object created for iui_date to represent it not being answered
        answer.reload
        expect(@cqv.check(answer)).to be_nil
      end

      it "should pass when pr_clin is #{pr_clin_trigger_value} and n_cl_et > 0" do
        answer = create(:answer, question: @pr_clin, answer_value: pr_clin_trigger_value, response: @response)
        create(:answer, question: @n_bl_et, answer_value: -1, response: @response)
        create(:answer, question: @n_cl_et, answer_value: 1, response: @response)
        # no answer object created for iui_date to represent it not being answered
        answer.reload
        expect(@cqv.check(answer)).to be_nil
      end

      it "should pass when pr_clin is #{pr_clin_trigger_value} and iui_date is a date" do
        answer = create(:answer, question: @pr_clin, answer_value: pr_clin_trigger_value, response: @response)
        create(:answer, question: @n_bl_et, answer_value: -1, response: @response)
        create(:answer, question: @n_cl_et, answer_value: -1, response: @response)
        create(:answer, question: @iui_date, answer_value: '2013-01-02', response: @response)
        answer.reload
        expect(@cqv.check(answer)).to be_nil
      end
    end
  end

  describe "RULE: gest_iui_date" do
    # rule_xx: if gestational age (pr_end_dt - iui_date) is greater than 20 weeks, n_deliv must be present
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

  describe "RULE: gest_et_date" do
    # rule_xx: if gestational age (pr_end_dt - et_date) is greater than 20 weeks, n_deliv must be present
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

  describe "RULE: ruleThawDon" do
    # ruleThawDon: if (n_s_clth + n_v_clth + n_s_blth + n_v_blth) > 0 and don_age is complete, thaw_don must be complete
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

  describe 'Rule: ruleDonAge' do
    # ruleDonAge: if surr=y & (n_s_clth + n_v_clth + n_s_blth + n_v_blth) > 0, don_age must be present
    before :each do
      @survey = create(:survey)
      @section = create(:section, survey: @survey)
      @surr = create(:question, code: 'SURR', section: @section, question_type: Question::TYPE_CHOICE)
      @n_s_clth = create(:question, code: 'N_S_CLTH', section: @section, question_type: Question::TYPE_INTEGER)
      @n_v_clth = create(:question, code: 'N_V_CLTH', section: @section, question_type: Question::TYPE_INTEGER)
      @n_s_blth = create(:question, code: 'N_S_BLTH', section: @section, question_type: Question::TYPE_INTEGER)
      @n_v_blth = create(:question, code: 'N_V_BLTH', section: @section, question_type: Question::TYPE_INTEGER)
      @don_age = create(:question, code: 'DON_AGE', section: @section, question_type: Question::TYPE_INTEGER)
      @cqv = create(:cross_question_validation, rule: 'special_rule_don_age', question: @don_age, error_message: 'My error message', related_question_id: nil)
      @response = create(:response, survey: @survey)
    end

    it 'should raise an error if used on the wrong question' do
      q = create(:question, code: 'Blah')
      cqv = build(:cross_question_validation, rule: 'special_rule_don_age', question: q)
      expect(cqv.valid?).to be false
      expect(cqv.errors[:base]).to eq ['special_rule_don_age requires question code DON_AGE but got Blah']
    end

    it 'should apply even when DON_AGE is unanswered' do
      expect(SpecialRules::RULES_THAT_APPLY_EVEN_WHEN_ANSWER_NIL).to include('special_rule_don_age')
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

  describe 'Rule: rule1mt' do
    # rule1mt: if n_embdisp =0, cyc_date-fdob must be ≥ 18 years & cyc_date-fdob must be <= 55 years
    # i.e if n_embdisp == 0 then cyc_date ≥ fdob + 18 years && cyc_date <= fdob + 55 years
    before :each do
      @survey = create(:survey)
      @section = create(:section, survey: @survey)
      @n_embdisp = create(:question, code: 'N_EMBDISP', section: @section, question_type: Question::TYPE_INTEGER)
      @cyc_date = create(:question, code: 'CYC_DATE', section: @section, question_type: Question::TYPE_DATE)
      @fdob = create(:question, code: 'FDOB', section: @section, question_type: Question::TYPE_DATE)
      @cqv = create(:cross_question_validation, rule: 'special_rule_1_mt', question: @n_embdisp, error_message: 'My error message', related_question_id: nil)
      @response = create(:response, survey: @survey)
    end

    it 'should raise an error if used on the wrong question' do
      q = create(:question, code: 'Blah')
      cqv = build(:cross_question_validation, rule: 'special_rule_1_mt', question: q)
      expect(cqv.valid?).to be false
      expect(cqv.errors[:base]).to eq ['special_rule_1_mt requires question code N_EMBDISP but got Blah']
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

  describe 'Rule: rule1mtdisp' do
    # rule1mtdisp: if n_embdisp >0, cyc_date-fdob must be ≥ 18 years & <= 70 years
    # i.e. if n_embdisp > 0 then cyc_date ≥ fdob + 18 years && cyc_date <= fdob + 70 years
    before :each do
      @survey = create(:survey)
      @section = create(:section, survey: @survey)
      @n_embdisp = create(:question, code: 'N_EMBDISP', section: @section, question_type: Question::TYPE_INTEGER)
      @cyc_date = create(:question, code: 'CYC_DATE', section: @section, question_type: Question::TYPE_DATE)
      @fdob = create(:question, code: 'FDOB', section: @section, question_type: Question::TYPE_DATE)
      @cqv = create(:cross_question_validation, rule: 'special_rule_1_mtdisp', question: @n_embdisp, error_message: 'My error message', related_question_id: nil)
      @response = create(:response, survey: @survey)
    end

    it 'should raise an error if used on the wrong question' do
      q = create(:question, code: 'Blah')
      cqv = build(:cross_question_validation, rule: 'special_rule_1_mtdisp', question: q)
      expect(cqv.valid?).to be false
      expect(cqv.errors[:base]).to eq ['special_rule_1_mtdisp requires question code N_EMBDISP but got Blah']
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

  describe 'Rule: rule24' do
    # rule24: n_ivf + n_icsi >=n_fert
    # i.e. n_fert <= n_ivf + n_icsi
    before :each do
      @survey = create(:survey)
      @section = create(:section, survey: @survey)
      @n_fert = create(:question, code: 'N_FERT', section: @section, question_type: Question::TYPE_INTEGER)
      @n_ivf = create(:question, code: 'N_IVF', section: @section, question_type: Question::TYPE_INTEGER)
      @n_icsi = create(:question, code: 'N_ICSI', section: @section, question_type: Question::TYPE_INTEGER)
      @cqv = create(:cross_question_validation, rule: 'special_rule_24', question: @n_fert, error_message: 'My error message', related_question_id: nil)
      @response = create(:response, survey: @survey)
    end

    it 'should raise an error if used on the wrong question' do
      q = create(:question, code: 'Blah')
      cqv = build(:cross_question_validation, rule: 'special_rule_24', question: q)
      expect(cqv.valid?).to be false
      expect(cqv.errors[:base]).to eq ['special_rule_24 requires question code N_FERT but got Blah']
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

  describe 'Rule: rule26h' do
    # rule26h: if et_date is a date, n_cl_et must be >=0 | n_bl_et must be >=0
    before :each do
      @survey = create(:survey)
      @section = create(:section, survey: @survey)
      @et_date = create(:question, code: 'ET_DATE', section: @section, question_type: Question::TYPE_DATE)
      @n_cl_et = create(:question, code: 'N_CL_ET', section: @section, question_type: Question::TYPE_INTEGER)
      @n_bl_et = create(:question, code: 'N_BL_ET', section: @section, question_type: Question::TYPE_INTEGER)
      @cqv = create(:cross_question_validation, rule: 'special_rule_26_h', question: @et_date, error_message: 'My error message', related_question_id: nil)
      @response = create(:response, survey: @survey)
    end

    it 'should raise an error if used on the wrong question' do
      q = create(:question, code: 'Blah')
      cqv = build(:cross_question_validation, rule: 'special_rule_26_h', question: q)
      expect(cqv.valid?).to be false
      expect(cqv.errors[:base]).to eq ['special_rule_26_h requires question code ET_DATE but got Blah']
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

end
