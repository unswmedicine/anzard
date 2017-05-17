class RenameBabyCodeToCycleId < ActiveRecord::Migration[5.0]
  def change
    rename_column :responses, :baby_code, :cycle_id
  end
end
