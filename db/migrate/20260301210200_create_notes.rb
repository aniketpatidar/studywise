class CreateNotes < ActiveRecord::Migration[8.0]
  def change
    create_table :notes do |t|
      t.references :material, null: false, foreign_key: true
      t.string :title, null: false
      t.text :content, null: false

      t.timestamps
    end

    add_index :notes, :created_at
  end
end
