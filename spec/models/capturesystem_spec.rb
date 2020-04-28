require 'rails_helper'

RSpec.describe Capturesystem, type: :model do
  describe "Associations" do
    it { expect have_many(:users).through(:capturesystem_users)}
    it { expect have_many(:surveys).through(:capturesystem_surveys)}
  end

  describe "Validations" do
    it { expect validate_presence_of(:name)}
    it { expect validate_uniqueness_of(:name).case_insensitive }
    it { expect validate_presence_of(:base_url)}
    it { expect validate_uniqueness_of(:base_url).case_insensitive }
  end
end
