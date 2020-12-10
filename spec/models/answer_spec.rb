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

describe Answer do
  let(:response) { create(:response) }
  let(:text_question) { create(:question, question_type: Question::TYPE_TEXT) }
  let(:integer_question) { create(:question, question_type: Question::TYPE_INTEGER) }
  let(:decimal_question) { create(:question, question_type: Question::TYPE_DECIMAL) }
  let(:date_question) { create(:question, question_type: Question::TYPE_DATE) }
  let(:time_question) { create(:question, question_type: Question::TYPE_TIME) }
  let(:choice_question) do
    cq = create(:question, question_type: Question::TYPE_CHOICE)
    create(:question_option, question: cq, option_value: '0', label: 'Dog')
    create(:question_option, question: cq, option_value: '1', label: 'Cat')
    create(:question_option, question: cq, option_value: '99', label: 'Apple')
    cq
  end

  describe "Associations" do
    it { should belong_to :response }
  end

  describe "Validations" do
    it { should validate_presence_of :question_id }
    it { should validate_presence_of :response }
  end

  describe "Validating for warnings" do
    let(:text_answer) { create(:answer, question: text_question, answer_value: "blah") }
    let(:integer_answer) { create(:answer, question: integer_question, answer_value: 34) }
    let(:decimal_answer) { create(:answer, question: decimal_question, answer_value: 1.13) }

    describe "Should call the string length validator if question type is text" do
      it "should record the warning if validation fails" do
        expect(StringLengthValidator).to receive(:validate).twice.with(text_question, "blah").and_return([false, "My string warning"])
        expect(text_answer.has_warning?).to eq true
        expect(text_answer.warnings).to eq ["My string warning"]
        expect(text_answer.fatal_warnings).to eq []
      end
    end

    describe "Should call the number validator if question type is integer" do
      it "should record the warning if validation fails" do
        expect(NumberRangeValidator).to receive(:validate).twice.with(integer_question, 34).and_return([false, "My integer warning"])
        expect(integer_answer.has_warning?).to eq true
        expect(integer_answer.warnings).to eq ["My integer warning"]
        expect(integer_answer.fatal_warnings).to eq []
      end
    end

    describe "Should call the number validator if question type is decimal" do
      it "should record the warning if validation fails" do
        expect(NumberRangeValidator).to receive(:validate).twice.with(decimal_question, 1.13).and_return([false, "My decimal warning"])
        expect(decimal_answer.has_warning?).to eq true
        expect(decimal_answer.warnings).to eq ["My decimal warning"]
        expect(decimal_answer.fatal_warnings).to eq []
      end
    end

    describe "Cross-question validation" do
      it "should record the warning if validation fails" do
        expect(CrossQuestionValidation).to receive(:check).twice.and_return(['error1', 'error2'])
        answer = create(:answer)

        expect(answer).to have_warning
        expect(answer.warnings).to eq ["error1", "error2"]
        expect(answer.fatal_warnings).to eq []
      end
    end

    describe "Validating that choice answers are one of the allowed values" do
      it "should pass when value is allowed" do
        answer = create(:answer, question: choice_question, answer_value: "99")
        expect(answer).to_not have_warning
      end
      it "should fail when value is not allowed" do
        answer = create(:answer, question: choice_question, answer_value: "98")
        expect(answer.fatal_warnings).to eq(['Answer must be one of ["0", "1", "99"]'])
        expect(answer).to have_warning
      end
    end
  end

  describe "comparable_answer should always return answers that can be compared using standard operators (<, >, ==, != etc)" do
    describe "answer_with_offset" do
      it "should return a comparable answer with an added offset" do
        q_choice = create(:answer, question: choice_question, answer_value: "98")
        q_dec = create(:answer, question: decimal_question, answer_value: "98")
        q_s = create(:answer, question: text_question, answer_value: "98")
        q_s2 = create(:answer, question: text_question, answer_value: "98")
        q_i = create(:answer, question: integer_question, answer_value: "98")
        q_date = create(:answer, question: date_question, answer_value: Date.today)
        q_time = create(:answer, question: time_question, answer_value: Time.now)

        #some select cases. the key thing is that they don't explode (but the logic should also never break)
        expect((q_choice.answer_with_offset(-1) < q_i.answer_with_offset(0))).to be true
        expect((q_choice.answer_with_offset(-1) > q_i.answer_with_offset(0))).to be false
        expect((q_choice.answer_with_offset(-1) < q_dec.answer_with_offset(0))).to be true
        expect((q_choice.answer_with_offset(-1) > q_dec.answer_with_offset(0))).to be false

        #offsets ignored for strings
        expect((q_s.answer_with_offset(45345) == q_s2.answer_with_offset(-2342323))).to be true
        expect((q_s.answer_with_offset(45345) != q_s2.answer_with_offset(-2342323))).to be false

        expect((q_date.answer_with_offset(1) > q_date.answer_with_offset(0))).to be true
        expect((q_date.answer_with_offset(1) < q_date.answer_with_offset(0))).to be false

        expect((q_time.answer_with_offset(1) > q_time.answer_with_offset(0))).to be true
        expect((q_time.answer_with_offset(1) < q_time.answer_with_offset(0))).to be false
      end

    end

    describe "comparable_answer" do
      it "should return comparable forms of everything" do
        #covered in answer_with_offset
      end
    end
  end

  describe "accept and sanitise all input (via assignment of answer_value), and have a warning if invalid" do
    describe "Decimal" do
      it "saves a decimal as a decimal" do
        a = create(:answer, question: decimal_question, answer_value: '1.23')
        expect(a.decimal_answer).to eq 1.23
      end
      it "saves an integer as a decimal" do
        a = create(:answer, question: decimal_question, answer_value: '123')
        expect(a.decimal_answer).to eq 123
      end
      it "saves invalid input as 'raw input' and has a warning" do
        a = create(:answer, question: decimal_question, answer_value: '1.23f')
        expect(a.decimal_answer).to be nil
        expect(a.raw_answer).to eq '1.23f'
        expect(a.has_warning?).to be true

      end
      # The answer record should be culled if it becomes empty, but if it gets left behind it should be blank.
      it "nils out on empty string" do
        a = create(:answer, question: decimal_question, decimal_answer: 1.23)
        expect(a.decimal_answer).to eq 1.23

        a.answer_value = ''
        expect(a.decimal_answer).to be nil
        expect(a.raw_answer).to be nil
      end
      it "does not nil out on invalid input, and has a warning" do
        a = create(:answer, question: decimal_question, decimal_answer: 1.23)
        expect(a.decimal_answer).to eq 1.23

        a.answer_value = 'garbage'
        expect(a.decimal_answer).to be nil
        expect(a.raw_answer).to eq 'garbage'
        expect(a.has_warning?).to be true

      end
    end
    describe "Integer" do

      it "saves an integer as an integer" do
        a = create(:answer, question: integer_question, answer_value: '1234')
        expect(a.integer_answer).to eq 1234
      end
      it "saves invalid input as 'raw input' and has a warning" do
        a = create(:answer, question: integer_question, answer_value: '1234d')
        expect(a.raw_answer).to eq '1234d'
        expect(a.has_warning?).to be true

      end
      it "nils out on empty string" do
        a = create(:answer, question: integer_question, integer_answer: 123)
        expect(a.integer_answer).to eq 123

        a.answer_value = ''
        expect(a.integer_answer).to be nil
        expect(a.raw_answer).to be nil
      end
      # The answer record should be culled if it becomes empty, but if it gets left behind it should be blank.
      it "does not nil out on invalid input and shows a warning" do
        a = create(:answer, question: integer_question, integer_answer: 123)
        expect(a.integer_answer).to eq 123

        a.answer_value = 'garbage'
        expect(a.integer_answer).to be nil
        expect(a.raw_answer).to eq 'garbage'
        expect(a.has_warning?).to be true

      end
    end

    describe "For date questions, should delegate to DateInputHandler to process the input" do
      it "should set the date answer if the input is valid" do
        date = Date.today
        mock_ih = double('mock input handler')
        expect(DateInputHandler).to receive(:new).and_return(mock_ih)
        expect(mock_ih).to receive(:valid?).and_return(true)
        expect(mock_ih).to receive(:to_date).and_return(date)
        a = create(:answer, question: date_question, answer_value: "abc")
        expect(a.date_answer).to be(date)
        expect(a.raw_answer).to be_nil
      end

      it "should set the raw answer if the input is invalid" do
        mock_ih = double('mock input handler')
        expect(DateInputHandler).to receive(:new).and_return(mock_ih)
        expect(mock_ih).to receive(:valid?).and_return(false)
        expect(mock_ih).to receive(:to_raw).and_return("blah")
        a = create(:answer, question: date_question, answer_value: "abc")
        expect(a.date_answer).to be_nil
        expect(a.raw_answer).to eq("blah")
      end
    end

    describe "For time questions, should delegate to TimeInputHandler to process the input" do
      it "should set the time answer if the input is valid" do
        time = Time.now.round.utc
        mock_ih = double('mock input handler')
        expect(TimeInputHandler).to receive(:new).and_return(mock_ih)
        expect(mock_ih).to receive(:valid?).and_return(true)
        expect(mock_ih).to receive(:to_time).and_return(time)
        a = build(:answer, question: time_question, answer_value: "abc")
        expect(a.time_answer).to eq(time)
        expect(a.raw_answer).to be_nil
      end

      it "should set the raw answer if the input is invalid" do
        mock_ih = double('mock input handler')
        expect(TimeInputHandler).to receive(:new).and_return(mock_ih)
        expect(mock_ih).to receive(:valid?).and_return(false)
        expect(mock_ih).to receive(:to_raw).and_return("blah")
        a = create(:answer, question: time_question, answer_value: "abc")
        expect(a.time_answer).to be_nil
        expect(a.raw_answer).to eq("blah")
      end
    end
  end

  describe "answer_value should contain the correct data on load with valid data" do
    it "Valid text" do
      a = create(:answer, question: text_question, answer_value: "abc")
      a.save!; a.answer_value = nil; a.reload
      expect(a.answer_value).to eq("abc")
    end
    it "Valid date" do
      date = Time.now.to_date
      date_hash = PartialDateTimeHash.new({day: date.day, month: date.month, year: date.year})
      a = create(:answer, question: date_question, answer_value: date_hash)
      a.save!; a.answer_value = nil; a.reload
      expect(PartialDateTimeHash.new(a.answer_value)).to eq(date_hash)
    end
    it "Valid time" do
      time_hash = PartialDateTimeHash.new(Time.now)
      a = create(:answer, question: time_question, answer_value: time_hash)
      a.save!; a.answer_value = nil; a.reload
      expect(PartialDateTimeHash.new(a.answer_value)).to eq(time_hash)
    end
    it "Valid decimal" do
      a = create(:answer, question: decimal_question, answer_value: "3.45")
      a.save!; a.answer_value = nil; a.reload
      expect(a.answer_value).to eq(3.45)
    end
    it "Valid integer" do
      a = create(:answer, question: integer_question, answer_value: "423")
      a.save!; a.answer_value = nil; a.reload
      expect(a.answer_value).to eq(423)
    end
    it "Valid choice" do
      a = create(:answer, question: choice_question, answer_value: "1")
      a.save!; a.answer_value = nil; a.reload
      expect(a.answer_value).to eq("1")
    end

  end

  describe "answer_value should contain the inputted data on load with invalid data, and a warning should be present" do

    it "invalid date from a string" do
      a = create(:answer, question: date_question, answer_value: "blah")
      a.reload
      expect(a.answer_value).to eq("blah")
      expect(a.has_warning?).to be true
      expect(a.fatal_warnings).to eq(["Answer is invalid (must be a valid date)"])
    end

    it "invalid date from a hash" do
      date_a_s_hash = ActiveSupport::HashWithIndifferentAccess.new ({day: 31, month: 2, year: 2000})
      date_hash = PartialDateTimeHash.new date_a_s_hash
      a = create(:answer, question: date_question, answer_value: date_a_s_hash)
      a.reload
      expect(a.answer_value).to eq(date_hash)
      expect(a.has_warning?).to be true
      expect(a.fatal_warnings).to eq(["Answer is invalid (Provided date does not exist)"])
    end

    it "partial date from a hash" do
      date_a_s_hash = ActiveSupport::HashWithIndifferentAccess.new ({day: 1, year: 2000})
      date_hash = PartialDateTimeHash.new date_a_s_hash
      a = create(:answer, question: date_question, answer_value: date_a_s_hash)
      a.reload
      expect(a.answer_value).to eq(date_hash)
      expect(a.has_warning?).to be true
      expect(a.fatal_warnings).to eq(["Answer is incomplete (one or more fields left blank)"])
    end

    it "invalid time from a string" do
      a = create(:answer, question: time_question, answer_value: "ab:11")
      a.reload
      expect(a.answer_value).to eq("ab:11")
      expect(a.has_warning?).to be true
      expect(a.fatal_warnings).to eq(["Answer is invalid (must be a valid time)"])
    end

    it "invalid time from a hash" do
      time_a_s_hash = ActiveSupport::HashWithIndifferentAccess.new ({hour: 20, min: 61})
      time_hash = PartialDateTimeHash.new time_a_s_hash
      a = create(:answer, question: time_question, answer_value: time_a_s_hash)
      a.reload
      expect(a.answer_value).to eq(time_hash)
      expect(a.has_warning?).to be true
      expect(a.fatal_warnings).to eq(["Answer is incomplete (a field was left blank)"])
    end

    it "partial time" do
      time_a_s_hash = ActiveSupport::HashWithIndifferentAccess.new ({hour: 20})
      time_hash = PartialDateTimeHash.new time_a_s_hash
      a = create(:answer, question: time_question, answer_value: time_a_s_hash)
      a.reload
      expect(a.answer_value).to eq(time_hash)
      expect(a.fatal_warnings).to eq(["Answer is incomplete (a field was left blank)"])
    end

    it "invalid integer" do
      input = "4.5"
      a = create(:answer, question: integer_question, answer_value: input)
      a.save!; b = Answer.find(a.id); a = b
      expect(a.answer_value).to eq(input)
      expect(a.has_warning?).to be true
    end

    it "invalid decimal" do
      input = "abc"
      a = create(:answer, question: decimal_question, answer_value: input)
      a.save!; b = Answer.find(a.id); a = b
      expect(a.answer_value).to eq(input)
      expect(a.has_warning?).to be true
    end

  end

  describe "Formatting an answer for display" do

    it "should handle each of the data types correctly" do
      expect(create(:answer, question: text_question, answer_value: "blah").format_for_display).to eq("blah")
      expect(create(:answer, question: integer_question, answer_value: "14").format_for_display).to eq("14")
      expect(create(:answer, question: decimal_question, answer_value: "14").format_for_display).to eq("14.0")
      expect(create(:answer, question: decimal_question, answer_value: "22.5").format_for_display).to eq("22.5")
      expect(create(:answer, question: decimal_question, answer_value: "22.59").format_for_display).to eq("22.59")
      expect(create(:answer, question: date_question, answer_value: PartialDateTimeHash.new({day: 31, month: 12, year: 2011})).format_for_display).to eq("31/12/2011")
      expect(create(:answer, question: time_question, answer_value: PartialDateTimeHash.new({hour: 18, min: 6})).format_for_display).to eq("18:06")

      expect(create(:answer, question: choice_question, answer_value: "99").format_for_display).to eq("(99) Apple")
    end

    it "should handle answers that are not filled out yet" do
      expect(create(:answer, question: text_question, answer_value: nil).format_for_display).to eq("Not answered")
      expect(create(:answer, question: integer_question, answer_value: nil).format_for_display).to eq("Not answered")
      expect(create(:answer, question: decimal_question, answer_value: nil).format_for_display).to eq("Not answered")
      expect(create(:answer, question: date_question, answer_value: nil).format_for_display).to eq("Not answered")
      expect(create(:answer, question: time_question, answer_value: nil).format_for_display).to eq("Not answered")
      expect(create(:answer, question: choice_question, answer_value: nil).format_for_display).to eq("Not answered")
    end

    it "should return blank for answers that are invalid" do
      expect(create(:answer, question: integer_question, raw_answer: "asdf").format_for_display).to eq("")

      expect(create(:answer, question: decimal_question, raw_answer: "asdf").format_for_display).to eq("")

      date_as_hash = ActiveSupport::HashWithIndifferentAccess.new ({day: 1, year: 2000})
      expect(create(:answer, question: date_question, raw_answer: PartialDateTimeHash.new(date_as_hash)).format_for_display).to eq("")

      time_as_hash = ActiveSupport::HashWithIndifferentAccess.new ({hour: 1})
      expect(create(:answer, question: time_question, raw_answer: PartialDateTimeHash.new(time_as_hash)).format_for_display).to eq("")
    end
  end

  describe "Formatting an answer for batch file detail report" do

    it "should handle each of the data types correctly" do
      expect(create(:answer, question: text_question, answer_value: "blah").format_for_csv).to eq("blah")
      expect(create(:answer, question: integer_question, answer_value: "14").format_for_csv).to eq("14")
      expect(create(:answer, question: decimal_question, answer_value: "14").format_for_csv).to eq("14.0")
      expect(create(:answer, question: decimal_question, answer_value: "22.5").format_for_csv).to eq("22.5")
      expect(create(:answer, question: decimal_question, answer_value: "22.59").format_for_csv).to eq("22.59")
      expect(create(:answer, question: date_question, answer_value: "31/12/2011").format_for_csv).to eq("2011-12-31")
      expect(create(:answer, question: time_question, answer_value: "18:06").format_for_csv).to eq("18:06")
      expect(create(:answer, question: choice_question, answer_value: "99").format_for_csv).to eq("99")
    end

    it "should return the raw answer for answers that are invalid" do
      expect(create(:answer, question: integer_question, raw_answer: "asdf").format_for_csv).to eq("asdf")
      expect(create(:answer, question: decimal_question, raw_answer: "asdf").format_for_csv).to eq("asdf")
      expect(create(:answer, question: date_question, raw_answer: "12/ff/3333").format_for_csv).to eq("12/ff/3333")
      expect(create(:answer, question: time_question, raw_answer: "18:ab").format_for_csv).to eq("18:ab")
    end
  end

end
