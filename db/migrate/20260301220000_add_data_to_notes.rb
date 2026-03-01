class AddDataToNotes < ActiveRecord::Migration[8.0]
  def change
    add_column :notes, :data, :jsonb, null: false, default: {}
    add_column :notes, :generation_mode, :string, null: false, default: "fallback"
  end
end
