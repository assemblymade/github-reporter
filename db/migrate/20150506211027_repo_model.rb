class RepoModel < ActiveRecord::Migration
  def change
    create_table :repos do |t|
      t.string :name
      t.string :owner
      t.string :changelog_name
      t.boolean :active
    end
  end
end
