class CustomTestSuite
  attr_reader :path, :schema_block

  class_attribute :instance, instance_accessor: false

  # @param path [String] path to sqlite DB that will be created for test
  def initialize(path, &block)
    @path = path
    @schema_block = block
  end

  def setup
    base_path = File.dirname(full_path)
    FileUtils.mkdir_p(base_path)
    ActiveRecord::Base.establish_connection(db_config.stringify_keys)
    ActiveRecord::Base.logger = Logger.new(STDOUT)
    ActiveRecord::Migration.verbose = false
    ActiveRecord::Schema.define(&schema_block)
  end

  def teardown
    FileUtils.rm(full_path) if File.exist?(full_path)
  end

  private

  def full_path
    File.absolute_path(path)
  end

  def db_config
    {
        adapter: 'sqlite3',
        database: path,
        pool: 1,
        timeout: 5_000
    }
  end
end

CustomTestSuite.instance = CustomTestSuite.new('tmp/test.sqlite') do
  create_table :users do |t|
    t.string :name
    t.integer :pricelist_id
  end
end
