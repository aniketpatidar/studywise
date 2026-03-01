class CreateMaterials < ActiveRecord::Migration[8.0]
  def change
    create_table :materials do |t|
      t.references :user, null: false, foreign_key: true
      t.string :title, null: false
      t.string :source_type, null: false, default: "text"
      t.string :source_url
      t.text :raw_text
      t.integer :status, null: false, default: 0

      t.timestamps
    end

    add_index :materials, :status
    add_index :materials, :source_type
  end
end
