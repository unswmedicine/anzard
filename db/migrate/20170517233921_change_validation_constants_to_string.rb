class ChangeValidationConstantsToString < ActiveRecord::Migration[5.0]
  def change
    change_column :cross_question_validations, :constant, :string
    change_column :cross_question_validations, :conditional_constant, :string
  end
end
