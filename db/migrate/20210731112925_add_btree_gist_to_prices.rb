class AddBtreeGistToPrices < ActiveRecord::Migration[6.1]
  # This migration requires CREATE privilege on database. To add it, use:
  # GRANT CREATE ON DATABASE piggy TO piggy;
  def change
    # CREATE EXTENSION btree_gist;
    # SELECT * FROM pg_extension;
    # DROP EXTENSION btree_gist;
    enable_extension :btree_gist

    # CREATE INDEX ON prices USING gist(actual_date);
    # SELECT indexname, indexdef FROM pg_indexes WHERE tablename = 'prices';
    # DROP INDEX prices_actual_date_idx;
    add_index :prices, :actual_date, using: 'gist'
  end
end
