class CreateMaterialChunks < ActiveRecord::Migration[8.0]
  def change
    create_table :material_chunks do |t|
      t.references :material, null: false, foreign_key: true
      t.integer :sequence, null: false
      t.text :chunk_text, null: false
      t.text :summary
      t.jsonb :embedding, null: false, default: []
      t.timestamps
    end
    add_index :material_chunks, [:material_id, :sequence], unique: true
  end
end
