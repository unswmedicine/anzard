require 'rails_helper'

describe Question do
  describe "Associations" do
    it { should belong_to :section }
    it { should have_many :answers }
    it { should have_many :question_options }
    it { should have_many :cross_question_validations }
  end

  describe "Validations" do
    describe "order" do
      it { should validate_presence_of :question_order }
      it "should validate that order is unique within a section" do
        first_q = create(:question)
        #should validate_uniqueness_of(:order).scoped_to :section_id
        second_q = build(:question, section: first_q.section, question_order: first_q.question_order)
        second_q.should_not be_valid
        diff_sec_q = build(:question, section: create(:section), question_order: first_q.question_order)
        diff_sec_q.should be_valid
      end
    end

    it { should validate_presence_of :section }
    it { should validate_presence_of :question }
    it { should validate_presence_of :code }
    it { should validate_presence_of :question_type }
    it { should validate_numericality_of(:number_min) }
    it { should validate_numericality_of(:number_max) }
    it { should validate_numericality_of(:number_unknown) }
    it { should validate_numericality_of(:string_min) }
    it { should validate_numericality_of(:string_max) }

    it "should validate that question type is one of the allowed types" do
      %w(Text Date Time Choice Decimal Integer).each do |value|
        should allow_value(value).for(:question_type)
      end
      build(:question, question_type: "Blah").should_not be_valid
    end
  end

  describe "Validate number range method" do
    it "should return false if both min and max are nil" do
      create(:question, number_min: nil, number_max: nil, number_unknown: nil).validate_number_range?.should be false
      create(:question, number_min: nil, number_max: nil, number_unknown: 123).validate_number_range?.should be false
    end

    it "should return true if either min or max is set" do
      create(:question, number_min: 1, number_max: nil, number_unknown: nil).validate_number_range?.should be true
      create(:question, number_min: nil, number_max: 99, number_unknown: nil).validate_number_range?.should be true
      create(:question, number_min: 1, number_max: 99, number_unknown: nil).validate_number_range?.should be true
      create(:question, number_min: 1, number_max: 99, number_unknown: 2).validate_number_range?.should be true
    end
  end

  describe "Validate string length method" do
    it "should return false if both min and max are nil" do
      create(:question, string_min: nil, string_max: nil).validate_string_length?.should be false
      create(:question, string_min: nil, string_max: nil).validate_string_length?.should be false
    end

    it "should return true if either min or max is set" do
      create(:question, string_min: 1, string_max: nil).validate_string_length?.should be true
      create(:question, string_min: nil, string_max: 99).validate_string_length?.should be true
      create(:question, string_min: 1, string_max: 99).validate_string_length?.should be true
      create(:question, string_min: 1, string_max: 99).validate_string_length?.should be true
    end
  end
end
