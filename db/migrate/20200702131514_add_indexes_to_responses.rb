class AddIndexesToResponses < ActiveRecord::Migration[5.0]
  def change
    add_index :responses, :survey_id
    add_index :responses, :clinic_id
  end
end
