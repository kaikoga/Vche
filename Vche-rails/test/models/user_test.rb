# == Schema Information
#
# Table name: users
#
#  id                           :bigint           not null, primary key
#  email                        :string(255)      not null
#  uid                          :string(255)      not null
#  display_name                 :string(255)
#  primary_sns                  :text(65535)
#  primary_sns_name             :text(65535)
#  icon_url                     :text(65535)
#  bio                          :text(65535)
#  visibility                   :string(255)      not null
#  trust                        :integer          not null
#  base_trust                   :integer          not null
#  user_role                    :string(255)      not null
#  admin_role                   :string(255)      not null
#  agreed_at                    :datetime
#  crypted_password             :string(255)
#  salt                         :string(255)
#  created_at                   :datetime         not null
#  updated_at                   :datetime         not null
#  remember_me_token            :string(255)
#  remember_me_token_expires_at :datetime
#  last_login_at                :datetime
#  last_logout_at               :datetime
#  last_activity_at             :datetime
#  last_login_from_ip_address   :string(255)
#  invalidate_sessions_before   :datetime
#
# Indexes
#
#  index_users_on_email                                (email) UNIQUE
#  index_users_on_last_logout_at_and_last_activity_at  (last_logout_at,last_activity_at)
#  index_users_on_remember_me_token                    (remember_me_token)
#
require 'test_helper'

class UserTest < ActiveSupport::TestCase
  # test "the truth" do
  #   assert true
  # end
end
