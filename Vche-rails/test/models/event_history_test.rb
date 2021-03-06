# == Schema Information
#
# Table name: event_histories
#
#  id                    :bigint           not null, primary key
#  uid                   :string(255)
#  event_id              :bigint           not null
#  resolution            :string(255)      not null
#  capacity              :integer          not null
#  default_audience_role :string(255)      not null
#  assembled_at          :datetime
#  opened_at             :datetime
#  started_at            :datetime         not null
#  ended_at              :datetime         not null
#  closed_at             :datetime
#  created_user_id       :bigint
#  updated_user_id       :bigint
#  created_at            :datetime         not null
#  updated_at            :datetime         not null
#
# Indexes
#
#  index_event_histories_on_created_user_id          (created_user_id)
#  index_event_histories_on_event_id                 (event_id)
#  index_event_histories_on_event_id_and_started_at  (event_id,started_at) UNIQUE
#  index_event_histories_on_uid                      (uid) UNIQUE
#  index_event_histories_on_updated_user_id          (updated_user_id)
#
# Foreign Keys
#
#  fk_rails_...  (created_user_id => users.id)
#  fk_rails_...  (event_id => events.id)
#  fk_rails_...  (updated_user_id => users.id)
#
require 'test_helper'

class EventHistoryTest < ActiveSupport::TestCase
  # test "the truth" do
  #   assert true
  # end
end
