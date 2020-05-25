class AddStatusToCapturesystemUsers < ActiveRecord::Migration[5.0]
  def change
    add_column :capturesystem_users, :access_status, :string
  end
end
