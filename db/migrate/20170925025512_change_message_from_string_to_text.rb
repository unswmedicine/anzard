class ChangeMessageFromStringToText < ActiveRecord::Migration[5.0]
  def self.up
    change_column :batch_files, :message, :text
  end

  def self.down
    change_column :batch_files, :message, :string
  end
end
