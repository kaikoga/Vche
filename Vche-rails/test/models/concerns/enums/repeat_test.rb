# == Schema Information
#
# Table name: accounts
#
#  id           :bigint           not null, primary key
#  uid          :string(255)
#  display_name :string(255)
#  platform_id  :bigint           not null
#  url          :string(255)
#  user_id      :bigint           not null
#  created_at   :datetime         not null
#  updated_at   :datetime         not null
#
# Indexes
#
#  index_accounts_on_platform_id  (platform_id)
#  index_accounts_on_uid          (uid) UNIQUE
#  index_accounts_on_user_id      (user_id)
#
# Foreign Keys
#
#  fk_rails_...  (platform_id => platforms.id)
#  fk_rails_...  (user_id => users.id)
#
require 'test_helper'

class Enums::RepeatTest < ActiveSupport::TestCase
  setup do
    @start_at = Time.zone.parse('2022-01-11 22:00:00')
    @end_at = Time.zone.parse('2022-01-11 23:00:00')
  end

  test '#next_instance for oneshot' do
    item = RepeatClass.new(start_at: @start_at, end_at: @end_at, repeat: :oneshot)
    travel_to(Time.zone.parse('2022-01-11 00:00:00')) do
      assert { item.next_instance == Time.zone.parse('2022-01-11 22:00:00') }
    end
    travel_to(Time.zone.parse('2022-01-11 23:59:59')) do
      assert { item.next_instance == Time.zone.parse('2022-01-11 22:00:00') }
    end
    travel_to(Time.zone.parse('2022-01-12 00:00:00')) do
      assert { item.next_instance == Time.zone.parse('2022-01-11 22:00:00') }
    end
  end

  test '#next_instance for every_day' do
    item = RepeatClass.new(start_at: @start_at, end_at: @end_at, repeat: :every_day)
    travel_to(Time.zone.parse('2022-01-11 00:00:00')) do
      assert { item.next_instance == Time.zone.parse('2022-01-11 22:00:00') }
    end
    travel_to(Time.zone.parse('2022-01-11 23:59:59')) do
      assert { item.next_instance == Time.zone.parse('2022-01-12 22:00:00') }
    end
    travel_to(Time.zone.parse('2022-01-12 00:00:00')) do
      assert { item.next_instance == Time.zone.parse('2022-01-12 22:00:00') }
    end
  end

  test '#next_instance for every_week' do
    item = RepeatClass.new(start_at: @start_at, end_at: @end_at, repeat: :every_week)
    travel_to(Time.zone.parse('2022-01-11 00:00:00')) do
      assert { item.next_instance == Time.zone.parse('2022-01-11 22:00:00') }
    end
    travel_to(Time.zone.parse('2022-01-11 23:59:59')) do
      assert { item.next_instance == Time.zone.parse('2022-01-18 22:00:00') }
    end
    travel_to(Time.zone.parse('2022-01-12 00:00:00')) do
      assert { item.next_instance == Time.zone.parse('2022-01-18 22:00:00') }
    end
  end

  test '#next_instance with schedule over midnight' do
    item = RepeatClass.new(start_at: @start_at, end_at: @start_at + 3.hours, repeat: :every_day)
    travel_to(Time.zone.parse('2022-01-11 00:00:00')) do
      assert { item.next_instance == Time.zone.parse('2022-01-11 22:00:00') }
    end
    travel_to(Time.zone.parse('2022-01-11 23:30:00')) do
      assert { item.next_instance == Time.zone.parse('2022-01-11 22:00:00') }
    end
    travel_to(Time.zone.parse('2022-01-12 00:30:00')) do
      assert { item.next_instance == Time.zone.parse('2022-01-11 22:00:00') }
    end
    travel_to(Time.zone.parse('2022-01-12 02:30:00')) do
      assert { item.next_instance == Time.zone.parse('2022-01-12 22:00:00') }
    end
  end

  test '#next_instance with schedule over multiple days' do
    item = RepeatClass.new(start_at: @start_at, end_at: @start_at + 3.days, repeat: :every_week)
    travel_to(Time.zone.parse('2022-01-11 00:00:00')) do
      assert { item.next_instance == Time.zone.parse('2022-01-11 22:00:00') }
    end
    travel_to(Time.zone.parse('2022-01-12 00:00:00')) do
      assert { item.next_instance == Time.zone.parse('2022-01-11 22:00:00') }
    end
    travel_to(Time.zone.parse('2022-01-13 23:30:00')) do
      assert { item.next_instance == Time.zone.parse('2022-01-11 22:00:00') }
    end
    travel_to(Time.zone.parse('2022-01-14 00:30:00')) do
      assert { item.next_instance == Time.zone.parse('2022-01-11 22:00:00') }
    end
    travel_to(Time.zone.parse('2022-01-15 02:30:00')) do
      assert { item.next_instance == Time.zone.parse('2022-01-18 22:00:00') }
    end
  end

  test '#next_instance with explicit close_at overrides end_at' do
    item = RepeatClass.new(start_at: @start_at, end_at: @end_at, close_at: @end_at + 30.minutes, repeat: :every_day)
    travel_to(Time.zone.parse('2022-01-11 00:00:00')) do
      assert { item.next_instance == Time.zone.parse('2022-01-11 22:00:00') }
    end
    travel_to(Time.zone.parse('2022-01-11 23:10:00')) do
      assert { item.next_instance == Time.zone.parse('2022-01-11 22:00:00') }
    end
    travel_to(Time.zone.parse('2022-01-11 23:40:00')) do
      assert { item.next_instance == Time.zone.parse('2022-01-12 22:00:00') }
    end
    travel_to(Time.zone.parse('2022-01-12 00:00:00')) do
      assert { item.next_instance == Time.zone.parse('2022-01-12 22:00:00') }
    end
  end

  class RepeatClass
    extend Enumerize

    include ActiveModel::Model
    include Enums::Repeat
    attr_accessor :start_at, :end_at, :close_at
  end
end
