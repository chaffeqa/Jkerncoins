class ChangePastLimitToIntegerInBlogElems < ActiveRecord::Migration
  def self.up
    change_table :blog_elems do |t|
      t.remove :past_limit
      t.integer :past_days_limit
    end
  end

  def self.down
    change_table :blog_elems do |t|
      t.remove :past_days_limit
      t.date :past_limit
    end
  end
end
