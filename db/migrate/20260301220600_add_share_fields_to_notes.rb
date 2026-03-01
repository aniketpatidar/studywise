class AddShareFieldsToNotes < ActiveRecord::Migration[8.0]
  def change
    add_column :notes, :share_token, :string
    add_column :notes, :shared_public, :boolean, null: false, default: false
    add_index :notes, :share_token, unique: true
  end
end
