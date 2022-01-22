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
class User < ApplicationRecord
  include Vche::Uid
  include Vche::UidQuery
  include Vche::Trust
  include Vche::AgreedAt

  include Enums::Visibility
  include Enums::UserRole
  include Enums::AdminRole
  include Enums::PrimarySns

  authenticates_with_sorcery!

  has_many :authentications, dependent: :destroy
  accepts_nested_attributes_for :authentications

  validates :password, length: { minimum: 3 }, if: -> { new_record? || changes[:crypted_password] }
  validates :password, confirmation: true, if: -> { new_record? || changes[:crypted_password] }
  validates :password_confirmation, presence: true, if: -> { new_record? || changes[:crypted_password] }

  validates :email, uniqueness: true, presence: true
  validates :visibility, unless: -> { validation_context == :destroy }, inclusion: { in: %w[public], message: 'を絞ったユーザーは未実装です' }

  validates :display_name, length: { in: 1..31 }
  validates :bio, length: { in: 0..4095 }, allow_blank: true

  has_many :accounts, dependent: :destroy
  has_many :event_memories, dependent: :destroy, inverse_of: :user
  has_many :shared_or_over_event_memories, -> { joins(:event).merge(Event.shared_or_over) }, class_name: 'EventMemory', dependent: nil, inverse_of: :user

  has_many :created_events, class_name: 'Event', foreign_key: :created_user_id, dependent: :nullify, inverse_of: :created_user
  has_many :updated_events, class_name: 'Event', foreign_key: :updated_user_id, dependent: :nullify, inverse_of: :updated_user
  has_many :created_event_schedules, class_name: 'EventSchedule', foreign_key: :created_user_id, dependent: :nullify, inverse_of: :created_user
  has_many :updated_event_schedules, class_name: 'EventSchedule', foreign_key: :updated_user_id, dependent: :nullify, inverse_of: :updated_user
  has_many :created_event_histories, class_name: 'EventHistory', foreign_key: :created_user_id, dependent: :nullify, inverse_of: :created_user
  has_many :updated_event_histories, class_name: 'EventHistory', foreign_key: :updated_user_id, dependent: :nullify, inverse_of: :updated_user
  has_many :created_event_follow_requests, class_name: 'EventFollowRequest', foreign_key: :created_user_id, dependent: :nullify, inverse_of: :created_user
  has_many :updated_event_follow_requests, class_name: 'EventFollowRequest', foreign_key: :updated_user_id, dependent: :nullify, inverse_of: :updated_user
  has_many :created_event_appeals, class_name: 'EventAppeal', foreign_key: :created_user_id, dependent: :nullify, inverse_of: :created_user
  has_many :updated_event_appeals, class_name: 'EventAppeal', foreign_key: :updated_user_id, dependent: :nullify, inverse_of: :updated_user

  has_many :all_event_follow_requests, class_name: 'EventFollowRequest', dependent: :destroy
  has_many :event_follow_requests, -> { secret_event_or_over }, dependent: nil, inverse_of: :user
  has_many :follow_requesting_events, through: :event_follow_requests, source: :event

  has_many :all_event_follows, dependent: :destroy
  has_many :event_follows, -> { secret_event_or_over }, dependent: nil, inverse_of: :user
  has_many :following_events, through: :event_follows, source: :event
  has_many :owned_follows, -> { owned.secret_event_or_over }, class_name: 'EventFollow', dependent: nil, inverse_of: :user
  has_many :owned_events, through: :owned_follows, source: :event
  has_many :backstage_follows, -> { backstage_member.secret_event_or_over }, class_name: 'EventFollow', dependent: nil, inverse_of: :user
  has_many :backstage_events, through: :backstage_follows, source: :event
  has_many :audience_follows, -> { audience.secret_event_or_over }, class_name: 'EventFollow', dependent: nil, inverse_of: :user
  has_many :audience_events, through: :audience_follows, source: :event

  has_many :all_event_attendances, class_name: 'EventAttendance', dependent: :destroy
  has_many :event_attendances, -> { secret_event_or_over }, dependent: nil, inverse_of: :user
  has_many :attending_events, through: :event_attendances, source: :event

  has_many :offline_schedules, dependent: :destroy

  has_many :feedbacks, dependent: :destroy

  def following_event?(event)
    event_follows.where(event: event).first&.role
  end

  def following_event_as_audience?(event)
    event_follows.audience.where(event: event).first&.role
  end

  def following_event_as_backstage_member?(event)
    event_follows.backstage_member.where(event: event).first&.role
  end

  def attending_event?(event_history)
    event_attendances.for_event_history(event_history).first&.role
  end

  def attending_event_as_audience?(event_history)
    event_attendances.audience.for_event_history(event_history).first&.role
  end

  def attending_event_as_backstage_member?(event_history)
    event_attendances.backstage_member.for_event_history(event_history).first&.role
  end

  def id_twitter=(value)
    self.email = "@@#{value}@twitter.com"
  end

  def twitter_icon_url=(value)
    self.icon_url = value.sub('_normal.', '_x96.')
  end
end
