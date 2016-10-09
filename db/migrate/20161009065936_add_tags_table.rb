class AddTagsTable < ActiveRecord::Migration
  def change
    create_table :tags do |t|
      t.text :title
      t.integer :parent_id
    end

    add_column :budget_records, :tag_id, :integer, default: 0
  end
end
