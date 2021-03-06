class Operations::Event::UpdateUserRole
  include Operations::Operation

  class UserIsOwner < StandardError; end

  def initialize(event:, user:, role:)
    @event = event
    @user = user
    @role = role&.to_sym
  end

  def validate
    raise ArgumentError if role == :irrelevant
    raise ArgumentError if role == :owner
    raise UserIsOwner if current_role == :owner
  end

  def perform
    if role
      event_follow = user.event_follows.create_or_find_by!(event: event)
      event_follow.update!(role: role)
      @user.become_staff! if EventFollow.backstage_role?(role)
    else
      user.event_follows.find_by!(event: event).destroy!
    end
  end

  private

  attr_reader :event, :user, :role

  def current_role
    user.event_follows.find_by(event: event)&.role&.to_sym || :irrelevant
  end
end
