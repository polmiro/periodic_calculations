require 'coveralls'
Coveralls.wear!

$LOAD_PATH << File.join(File.dirname(__FILE__), '..', 'lib')

require 'rails/all'
require 'rspec/rails'
require 'count_during'

ActiveRecord::Base.establish_connection(adapter: "sqlite3", database: ":memory:")

ActiveRecord::Schema.define(version: 1) do
  create_table :test_models do |t|
    t.integer :number
    t.timestamps
  end
end

class TestModel < ActiveRecord::Base
end

def clean_database
  models = [TestModel]
  models.each do |model|
    ActiveRecord::Base.connection.execute "DELETE FROM #{model.table_name}"
  end
end