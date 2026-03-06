class AddIdempotencyKeysToGeneratedContent < ActiveRecord::Migration[8.0]
  def change
    add_column :notes, :idempotency_key, :string
    add_column :quizzes, :idempotency_key, :string

    add_index :notes, [ :material_id, :idempotency_key ], unique: true
    add_index :quizzes, [ :material_id, :idempotency_key ], unique: true
  end
end
