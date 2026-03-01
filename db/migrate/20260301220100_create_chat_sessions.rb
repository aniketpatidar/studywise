class CreateChatSessions < ActiveRecord::Migration[8.0]
  def change
    create_table :chat_sessions do |t|
      t.references :user, null: false, foreign_key: true
      t.references :material, foreign_key: true
      t.string :mode, null: false
      t.string :subject_name
      t.string :title

      t.timestamps
    end

    add_index :chat_sessions, %i[user_id mode]
  end
end
