class AddUniqueIndexToQuizAttempts < ActiveRecord::Migration[8.0]
  def up
    execute <<~SQL
      DELETE FROM quiz_attempts a
      USING quiz_attempts b
      WHERE a.id > b.id
        AND a.quiz_id = b.quiz_id
        AND a.user_id = b.user_id;
    SQL

    add_index :quiz_attempts, %i[quiz_id user_id], unique: true
  end

  def down
    remove_index :quiz_attempts, column: %i[quiz_id user_id]
  end
end
