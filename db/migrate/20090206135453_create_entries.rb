class CreateEntries < ActiveRecord::Migration
  def self.up
    create_table :entries do |t|
      t.string :expression
      t.string :reading
      t.string :definition
      t.integer :status, :default => 1

      t.timestamps
    end
  end

  def self.down
    drop_table :entries
  end
end
