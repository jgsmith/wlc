class CreateUsers < ActiveRecord::Migration
  def self.up
    create_table "users", :force => true do |t|
      t.column :login,                     :string
      t.column :email,                     :string
      t.column :crypted_password,          :string, :limit => 40
      t.column :salt,                      :string, :limit => 40
      t.column :created_at,                :datetime
      t.column :updated_at,                :datetime
      t.column :remember_token,            :string
      t.column :remember_token_expires_at, :datetime
    end

    User.create :login => 'jgsmith', :email => 'email1@tamu.edu', :password => 'good4now', :password_confirmation => 'good4now'
    User.create :login => 'user2', :email => 'email2@tamu.edu', :password => 'good4now', :password_confirmation => 'good4now'
    User.create :login => 'user3', :email => 'email3@tamu.edu', :password => 'good4now', :password_confirmation => 'good4now'
    User.create :login => 'user4', :email => 'email4@tamu.edu', :password => 'good4now', :password_confirmation => 'good4now'
  end

  def self.down
    drop_table "users"
  end
end
