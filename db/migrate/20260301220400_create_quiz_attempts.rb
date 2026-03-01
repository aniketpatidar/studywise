class CreateQuizAttempts < ActiveRecord::Migration[8.0]
  def change
    create_table :quiz_attempts do |t|
      t.references :quiz, null: false, foreign_key: true
      t.references :user, null: false, foreign_key: true
      t.integer :score, null: false, default: 0
      t.integer :total, null: false, default: 0
      t.jsonb :answers, null: false, default: {}

      t.timestamps
    end
  end
end
