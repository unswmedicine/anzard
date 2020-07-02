class AddIndexesToSections < ActiveRecord::Migration[5.0]
  def change
    add_index :sections, :survey_id
  end
end
