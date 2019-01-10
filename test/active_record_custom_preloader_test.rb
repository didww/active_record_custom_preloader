require 'test_helper'

class ActiveRecordCustomPreloaderTest < Minitest::Test
  def setup
    CustomTestSuite.instance.setup
  end

  def teardown
    CustomTestSuite.instance.teardown
  end

  def test_that_it_has_a_version_number
    refute_nil ::ActiveRecordCustomPreloader::VERSION
  end

  def test_simple_preload
    user1 = User.create(name: 'john', pricelist_id: 1)
    user2 = User.create(name: 'jane', pricelist_id: 1)
    User.create(name: 'bob', pricelist_id: 2)
    scope = User.all.preload(:_simple)

    all_result = scope.where(pricelist_id: 1).order(id: :asc).to_a
    assert_equal 2, all_result.size
    assert_equal [user1.id, user2.id], all_result.first._simple.ids
    assert_equal user1.id, all_result.first._simple.record_id
    assert_equal [user1.id, user2.id], all_result.second._simple.ids
    assert_equal user2.id, all_result.second._simple.record_id
  end

  def test_preload_with_options
    user1 = User.create(name: 'john', pricelist_id: 1)
    user2 = User.create(name: 'jane', pricelist_id: 1)
    User.create(name: 'bob', pricelist_id: 2)
    args = { foo: 'bar'}
    scope = User.all.custom_preload(:_simple, args)

    all_result = scope.where(pricelist_id: 1).order(id: :asc).to_a
    assert_equal 2, all_result.size
    assert_equal [user1.id, user2.id], all_result.first._simple.ids
    assert_equal user1.id, all_result.first._simple.record_id
    assert_equal args, all_result.first._simple.args
    assert_equal [user1.id, user2.id], all_result.second._simple.ids
    assert_equal user2.id, all_result.second._simple.record_id
    assert_equal args, all_result.second._simple.args
  end

  def test_not_preloaded
    user1 = User.create(name: 'john')
    User.create(name: 'jane')
    scope = User.all

    all_result = scope.order(id: :asc).to_a
    assert_equal 2, all_result.size
    assert_equal [user1.id], all_result.first._simple.ids
    assert_equal user1.id, all_result.first._simple.record_id
  end
end
