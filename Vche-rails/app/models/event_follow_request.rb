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
class EventFollowRequest < ApplicationRecord
  include Enums::Role

  include Vche::Scopes::UserScopes
  include Vche::Scopes::EventScopes

  include Vche::Uid
  include Vche::UidQuery
  include Vche::EditorFields

  validates :role, if: -> { started_at == nil }, exclusion: { in: %w[owner irrelevant], message: 'ではフォロー申請できません' }
  validates :role, if: -> { started_at != nil }, exclusion: { in: %w[irrelevant], message: 'ではフォロー申請できません' }

  belongs_to :user
  belongs_to :event
  belongs_to :approver, class_name: 'User'

  scope :undetermined, -> { where(state: nil) }

  def find_or_build_history
    event.find_or_build_history(started_at) if started_at
  end

  def accept
    if started_at
      Operations::EventHistory::UpdateUserRole.new(event_history: find_or_build_history, user: user, role: role).perform
    else
      Operations::Event::UpdateUserRole.new(event: event, user: user, role: role).perform
    end
    update!(state: 'accepted')
  rescue Operations::Event::UpdateUserRole::UserIsOwner
    update!(state: 'already_owner')
  end

  def decline
    update!(state: 'declined')
  end

  def withdraw
    update!(state: 'withdrawed')
  end
end
