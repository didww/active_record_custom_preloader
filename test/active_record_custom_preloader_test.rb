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

  def test_array_foreign_keys_loader
    dep1 = Department.create!(name: 'manager')
    dep2 = Department.create!(name: 'developer')
    dep3 = Department.create!(name: 'support')
    user1 = User.create! name: 'John Doe', department_ids: [dep2.id, dep1.id]
    user2 = User.create! name: 'Jane Doe', department_ids: [dep3.id, nil]
    user3 = User.create! name: 'Bob', department_ids: nil
    scope = User.all.preload(:_departments)
    collection = scope.order(id: :asc).to_a

    assert_equal 3, collection.size

    assert_equal user1.id, collection.first.id
    assert_equal [dep2.id, dep1.id], collection.first._departments.map(&:id)

    assert_equal user2.id, collection.second.id
    assert_equal [dep3.id], collection.second._departments.map(&:id)

    assert_equal user3.id, collection.third.id
    assert_equal [], collection.third._departments
  end

  def test_combine_with_ar_assocs
    pricelist = Pricelist.create!(name: 'main')
    pricelist2 = Pricelist.create!(name: 'secondary')
    user1 = User.create(name: 'john', pricelist_id: pricelist.id)
    user2 = User.create(name: 'jane', pricelist_id: pricelist.id)
    User.create(name: 'bob', pricelist_id: pricelist2.id)
    Comment.create!(user_id: user1.id, text: 'qwe')
    Comment.create!(user_id: user1.id, text: 'asd')
    Comment.create!(user_id: user2.id, text: 'zxc')
    ApiAccess.create!(user_id: user1.id, token: 'test')
    scope = User.all.preload(:comments, :api_access, :pricelist, :_simple)

    all_result = scope.where(pricelist_id: 1).order(id: :asc).to_a
    assert_equal 2, all_result.size
    assert_equal [user1.id, user2.id], all_result.first._simple.ids
    assert_equal user1.id, all_result.first._simple.record_id
    assert_equal [user1.id, user2.id], all_result.second._simple.ids
    assert_equal user2.id, all_result.second._simple.record_id

    assert all_result.first.association(:comments).loaded?
    assert all_result.second.association(:comments).loaded?
    assert 2, all_result.first.comments.size
    assert 1, all_result.second.comments.size

    assert all_result.first.association(:api_access).loaded?
    assert all_result.second.association(:api_access).loaded?
    assert all_result.first.api_access.present?
    assert_nil all_result.second.api_access

    assert all_result.first.association(:pricelist).loaded?
    assert all_result.second.association(:pricelist).loaded?
    assert_equal pricelist, all_result.first.pricelist
    assert_equal pricelist, all_result.second.pricelist
  end
end
