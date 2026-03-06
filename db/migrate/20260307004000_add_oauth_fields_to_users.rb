class AddOauthFieldsToUsers < ActiveRecord::Migration[8.0]
  def change
    add_column :users, :oauth_provider, :string
    add_column :users, :oauth_uid, :string
    add_index :users, %i[oauth_provider oauth_uid], unique: true
  end
end
