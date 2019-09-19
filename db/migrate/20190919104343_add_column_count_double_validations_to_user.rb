class AddColumnCountDoubleValidationsToUser < ActiveRecord::Migration[5.0]
  def change
    add_column :users, :accessdouble_validation_count, :integer
  end
end
