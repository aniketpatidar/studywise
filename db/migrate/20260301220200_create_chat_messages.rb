class CreateChatMessages < ActiveRecord::Migration[8.0]
  def change
    create_table :chat_messages do |t|
      t.references :chat_session, null: false, foreign_key: true
      t.string :role, null: false
      t.text :content, null: false

      t.timestamps
    end

    add_index :chat_messages, %i[chat_session_id created_at]
  end
end
