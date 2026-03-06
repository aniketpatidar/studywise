class AddSlugToChatSessions < ActiveRecord::Migration[8.0]
  def change
    add_column :chat_sessions, :slug, :string
    add_index :chat_sessions, :slug, unique: true
  end
end
