class AddBuilderIntoBuildList < ActiveRecord::Migration
  def change
    add_column :build_lists, :builder_id, :integer, references: nil
  end
end
