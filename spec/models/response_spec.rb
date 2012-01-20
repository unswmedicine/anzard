require 'spec_helper'

describe Response do
  describe "Associations" do
    it { should belong_to :survey }
    it { should belong_to :user }
    it { should have_many :answers }
  end
  describe "Validations" do
    it { should validate_presence_of :baby_code }
    it { should validate_presence_of :user }
    it { should validate_presence_of :survey }
  end
end
