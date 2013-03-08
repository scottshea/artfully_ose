class AddCategoriesToEvents < ActiveRecord::Migration
  def change
    add_column :events, :public, :boolean, :default => false
    add_column :events, :primary_category, :string
    add_column :events, :secondary_categories, :text
    execute "update events set primary_category = 'Other'"
  end
end
