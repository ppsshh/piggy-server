class AddUsersTable < ActiveRecord::Migration[7.0]
  def change
    create_table :users do |t|
      t.string :username
      t.string :pwd_hash
      t.string :pwd_salt
      t.text :memo
    end
  end
end
