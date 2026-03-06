class AddAdminToUsers < ActiveRecord::Migration[8.0]
  def up
    add_column :users, :admin, :boolean, default: false, null: false
    execute <<~SQL.squish
      UPDATE users
      SET admin = TRUE
      WHERE id = (SELECT MIN(id) FROM users)
    SQL
  end

  def down
    remove_column :users, :admin
  end
end
