class ChangeErrorMessageFromStringToText < ActiveRecord::Migration[5.0]
  def self.up
    change_column :cross_question_validations, :error_message, :text
  end

  def self.down
    change_column :cross_question_validations, :error_message, :string
  end
end
