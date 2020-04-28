class CreateCapturesystemUsers < ActiveRecord::Migration[5.0]
  def change
    create_table :capturesystem_users do |t|
      t.belongs_to :capturesystem
      t.belongs_to :user

      t.index [:capturesystem_id, :user_id], unique: true
      t.index [:user_id, :capturesystem_id], unique: true

      t.timestamps
    end
  end
end
