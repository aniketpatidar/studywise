class CreateLlmEvents < ActiveRecord::Migration[8.0]
  def change
    create_table :llm_events do |t|
      t.references :user, foreign_key: true
      t.references :material, foreign_key: true
      t.string :provider, null: false
      t.string :model, null: false
      t.string :operation, null: false
      t.boolean :success, null: false, default: false
      t.integer :status_code
      t.integer :latency_ms
      t.integer :prompt_chars, null: false, default: 0
      t.integer :response_chars, null: false, default: 0
      t.text :error_message

      t.timestamps
    end

    add_index :llm_events, %i[user_id created_at]
    add_index :llm_events, %i[material_id created_at]
  end
end
