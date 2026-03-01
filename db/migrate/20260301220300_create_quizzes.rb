class CreateQuizzes < ActiveRecord::Migration[8.0]
  def change
    create_table :quizzes do |t|
      t.references :material, null: false, foreign_key: true
      t.string :title, null: false
      t.jsonb :questions, null: false, default: []
      t.string :generation_mode, null: false, default: "fallback"

      t.timestamps
    end
  end
end
