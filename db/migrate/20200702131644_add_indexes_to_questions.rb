class AddIndexesToQuestions < ActiveRecord::Migration[5.0]
  def change
    add_index :questions, :section_id
  end
end
