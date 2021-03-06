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
class EventHistory < ApplicationRecord
  include Vche::Uid
  include Vche::EditorFields
  include Vche::RepeatInstance

  include Enums::Resolution
  include Enums::DefaultAudienceRole

  validates :resolution, unless: :official?, exclusion: { in: %w[scheduled announced], message: 'は主催のいるイベント用の状態です' }
  validates :resolution, exclusion: { in: %w[phantom], message: 'は選択できない状態です' }
  validates :started_at, presence: true
  validates :ended_at, presence: true

  belongs_to :event

  delegate :trust, :hashtag, to: :event

  after_initialize :recalculate_resolution

  before_validation :recalculate_capacity

  after_save :cleanup_stale_schedule

  delegate :official?, to: :event

  def event_attendances
    event.event_attendances.where(started_at: started_at)
  end

  def event_owners
    event_attendances.owned
  end

  def owners
    event_owners.map(&:user)
  end

  def event_backstage_members
    event_attendances.backstage_member
  end

  def backstage_members
    event_backstage_members.map(&:user)
  end

  def event_audiences
    event_attendances.audience
  end

  def audiences
    event_audiences.map(&:user)
  end

  def trust_unique_key
    hashtag ? [hashtag, started_at] : []
  end

  def to_key
    [to_param]
  end

  def to_param
    started_at&.strftime('%Y%m%d%H%M%S')
  end

  def scheduled?
    event.scheduled_at?(started_at)
  end

  def event_appeal_for(user)
    appeal = event.event_appeals.available.find_by(appeal_role: :personal, user: user)
    return appeal if appeal

    appeal_role = use_backstage_appeal_for?(user) ? :backstage : :audience
    event.event_appeals.available.find_by(appeal_role: appeal_role) || EventAppeal::Default.new(event)
  end

  private

  def recalculate_resolution
    return unless ended_at

    if Time.zone.now >= ended_at
      self.resolution =
        case resolution.to_sym
        when :scheduled, :announced, :information
          :ended
        else
          resolution
        end
    end
  end

  def recalculate_capacity
    self.capacity ||= 0
  end

  def use_backstage_appeal_for?(user)
    return nil unless user

    user.attending_event_as_backstage_member?(self) || user.following_event_as_backstage_member?(event)
  end

  def cleanup_stale_schedule
    return unless resolution.in? ['moved', 'canceled', 'completed']

    oneshot_event_schedules = event.event_schedules.where(start_at: started_at, repeat: :oneshot)
    oneshot_event_schedules.delete_all
  end
end
