class CreateCapturesystems < ActiveRecord::Migration[5.0]
  def change
    create_table :capturesystems do |t|
      t.string :name
      t.string :base_url

      t.timestamps
    end
  end
end
