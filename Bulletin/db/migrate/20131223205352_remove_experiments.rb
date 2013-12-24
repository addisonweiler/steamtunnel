class RemoveExperiments < ActiveRecord::Migration
  def change
    	drop_table :experiments
  end
end