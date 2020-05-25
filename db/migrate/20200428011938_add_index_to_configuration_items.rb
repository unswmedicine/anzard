class AddIndexToConfigurationItems < ActiveRecord::Migration[5.0]
  def change
    add_index :configuration_items, :name, unique: true
  end
end
