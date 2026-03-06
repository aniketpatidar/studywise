class AddSlugToMaterials < ActiveRecord::Migration[8.0]
  def change
    add_column :materials, :slug, :string
    add_index :materials, :slug, unique: true
  end
end
