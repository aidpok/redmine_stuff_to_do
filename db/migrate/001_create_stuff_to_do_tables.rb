class CreateStuffToDoTables < ActiveRecord::Migration[7.2]
  def up
    unless table_exists?(:stuff_to_dos)
      create_table :stuff_to_dos do |t|
        t.integer :user_id
        t.integer :position
        t.integer :stuff_id
        t.string :stuff_type
      end
    end

    add_index :stuff_to_dos, :user_id unless index_exists?(:stuff_to_dos, :user_id)
    add_index :stuff_to_dos, :stuff_id unless index_exists?(:stuff_to_dos, :stuff_id)
    add_index :stuff_to_dos, :stuff_type unless index_exists?(:stuff_to_dos, :stuff_type)

  end

  def down
    drop_table :stuff_to_dos if table_exists?(:stuff_to_dos)
  end
end
