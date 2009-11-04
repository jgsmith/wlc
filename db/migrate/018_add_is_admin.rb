class AddIsAdmin < ActiveRecord::Migration
  def self.up
    add_column :users, :is_admin, :boolean, :default => false
  end

  def self.down
    drop_column :users, :is_admin
  end
end
