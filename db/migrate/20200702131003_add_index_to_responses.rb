class AddIndexToResponses < ActiveRecord::Migration[5.0]
  def change
    add_index :responses, [:survey_id, :year_of_registration, :cycle_id], unique: true, name: 'index_response_for_upload_records'
  end
end
