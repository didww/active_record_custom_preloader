require 'test_helper'

class ActiveRecordCustomPreloaderTest < Minitest::Test
  def setup
    CustomTestSuite.instance.setup
  end

  def teardown
    CustomTestSuite.instance.teardown
    SimplePreloader._called = 0
    UserDepartmentsPreloader._called = 0
    UserPricesPreloader._called = 0
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
    assert_equal 1, SimplePreloader._called
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
    assert_equal 1, SimplePreloader._called
  end

  def test_not_preloaded
    user1 = User.create(name: 'john')
    User.create(name: 'jane')
    scope = User.all

    all_result = scope.order(id: :asc).to_a
    assert_equal 2, all_result.size
    assert_equal [user1.id], all_result.first._simple.ids
    assert_equal user1.id, all_result.first._simple.record_id
    assert_equal 1, SimplePreloader._called
    all_result.second._simple
    assert_equal 2, SimplePreloader._called
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
    assert_equal 1, UserDepartmentsPreloader._called
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
    assert_equal 1, SimplePreloader._called
  end

  def test_duplicate_simple_preload
    pricelist = Pricelist.create!(name: 'test')
    User.create!(name: 'john', pricelist_id: pricelist.id)
    User.create!(name: 'jane', pricelist_id: pricelist.id)

    scope = Pricelist
            .all
            .preload(users: :_simple)
            .preload(users: [:comments, :_simple])

    all_result = scope.to_a
    users = all_result.map(&:users).flatten
    assert_equal 2, users.size
    assert_equal 1, SimplePreloader._called
    users.first._simple
    users.second._simple
    assert_equal 1, SimplePreloader._called
  end

  def test_custom_preloads_collection_with_nested
    pricelist_1 = Pricelist.create!(name: 'pricelist_1')
    pricelist_2 = Pricelist.create!(name: 'pricelist_2')
    price_bundle_1 = PriceBundle.create!(name: 'price_bundle_1')
    price_bundle_2 = PriceBundle.create!(name: 'price_bundle_2')
    User.create!(name: 'user_11', pricelist: pricelist_1, price_bundle: price_bundle_1)
    User.create!(name: 'user_12', pricelist: pricelist_1, price_bundle: price_bundle_2)
    User.create!(name: 'user_21', pricelist: pricelist_2, price_bundle: price_bundle_1)
    User.create!(name: 'user_0')

    # user_11 has 2 prices
    Price.create!(price: 1.11, pricelist: pricelist_1, price_bundle: price_bundle_1)
    Price.create!(price: 1.12, pricelist: pricelist_1, price_bundle: price_bundle_1)

    # user_12 has 0 prices
    # user_0 has 0 prices

    # user_21 has 1 price
    Price.create!(price: 2.11, pricelist: pricelist_2, price_bundle: price_bundle_1)

    scope = User.all.preload(
      _prices: [
        :pricelist,
        :_simple
      ]
    )
    all_result = scope.to_a

    user_11 = all_result.detect { |r| r.pricelist_id == pricelist_1.id && r.price_bundle_id == price_bundle_1.id }
    user_12 = all_result.detect { |r| r.pricelist_id == pricelist_1.id && r.price_bundle_id == price_bundle_2.id }
    user_21 = all_result.detect { |r| r.pricelist_id == pricelist_2.id && r.price_bundle_id == price_bundle_1.id }
    user_0 = all_result.detect { |r| r.pricelist_id.nil? && r.price_bundle_id.nil? }

    assert_equal 1, UserPricesPreloader._called
    assert_equal 1, SimplePreloader._called

    assert_equal [1.11, 1.12], user_11._prices.map(&:price)
    user_11._prices.each do |price|
      assert price.association(:pricelist).loaded?
      price._simple
    end

    assert_equal [], user_12._prices
    assert_equal [], user_0._prices

    assert_equal [2.11], user_21._prices.map(&:price)
    price_21 = user_21._prices.first
    assert price_21.association(:pricelist).loaded?
    price_21._simple

    assert_equal 1, UserPricesPreloader._called
    assert_equal 1, SimplePreloader._called
  end

  def test_custom_preloads_single_with_nested
    pricelist_1 = Pricelist.create!(name: 'pricelist_1')
    pricelist_2 = Pricelist.create!(name: 'pricelist_2')
    price_bundle_1 = PriceBundle.create!(name: 'price_bundle_1')
    price_bundle_2 = PriceBundle.create!(name: 'price_bundle_2')
    User.create!(name: 'user_11', pricelist: pricelist_1, price_bundle: price_bundle_1)
    User.create!(name: 'user_12', pricelist: pricelist_1, price_bundle: price_bundle_2)
    User.create!(name: 'user_21', pricelist: pricelist_2, price_bundle: price_bundle_1)
    User.create!(name: 'user_0')

    # user_11 has discount
    Discount.create!(percent: 11, pricelist: pricelist_1, price_bundle: price_bundle_1)

    # user_12 has no discount
    # user_0 has no discount

    # user_21 has discount
    Discount.create!(percent: 21, pricelist: pricelist_2, price_bundle: price_bundle_1)

    scope = User.all.preload(
      _discount: [
        :pricelist,
        :_simple
      ]
    )
    all_result = scope.to_a

    user_11 = all_result.detect { |r| r.pricelist_id == pricelist_1.id && r.price_bundle_id == price_bundle_1.id }
    user_12 = all_result.detect { |r| r.pricelist_id == pricelist_1.id && r.price_bundle_id == price_bundle_2.id }
    user_21 = all_result.detect { |r| r.pricelist_id == pricelist_2.id && r.price_bundle_id == price_bundle_1.id }
    user_0 = all_result.detect { |r| r.pricelist_id.nil? && r.price_bundle_id.nil? }

    assert_equal 1, UserDiscountPreloader._called
    assert_equal 1, SimplePreloader._called

    assert_equal 11, user_11._discount.percent
    assert user_11._discount.association(:pricelist).loaded?
    user_11._discount._simple

    assert_nil user_12._discount
    assert_nil user_0._discount

    assert_equal 21, user_21._discount.percent
    assert user_21._discount.association(:pricelist).loaded?
    user_21._discount._simple

    assert_equal 1, UserDiscountPreloader._called
    assert_equal 1, SimplePreloader._called
  end
end
