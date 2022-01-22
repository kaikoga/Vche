# == Schema Information
#
# Table name: event_follow_requests
#
#  id              :bigint           not null, primary key
#  uid             :string(255)
#  user_id         :bigint           not null
#  event_id        :bigint           not null
#  approver_id     :bigint           not null
#  role            :string(255)      not null
#  started_at      :datetime
#  message         :string(255)      not null
#  state           :string(255)
#  created_user_id :bigint
#  updated_user_id :bigint
#  created_at      :datetime         not null
#  updated_at      :datetime         not null
#
# Indexes
#
#  index_event_follow_requests_on_approver_id            (approver_id)
#  index_event_follow_requests_on_approver_id_and_state  (approver_id,state)
#  index_event_follow_requests_on_event_id               (event_id)
#  index_event_follow_requests_on_event_id_and_state     (event_id,state)
#  index_event_follow_requests_on_uid                    (uid) UNIQUE
#  index_event_follow_requests_on_user_id                (user_id)
#
# Foreign Keys
#
#  fk_rails_...  (approver_id => users.id)
#  fk_rails_...  (event_id => events.id)
#  fk_rails_...  (user_id => users.id)
#
ActiveAdmin.register EventFollowRequest do
  menu parent: :user
end
