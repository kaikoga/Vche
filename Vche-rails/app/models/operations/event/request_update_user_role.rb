class Operations::Event::RequestUpdateUserRole
  include Operations::Operation

  class UserIsOwner < StandardError; end

  def initialize(event:, creator:, user:, approver:, role:)
    @event = event
    @creator = creator
    @user = user
    @approver = approver
    @role = role&.to_sym
  end

  def validate
    raise ArgumentError if role == :irrelevant
    raise ArgumentError if role == :owner
    raise UserIsOwner if current_role == :owner
  end

  def perform
    if role
      event_follow_requests.find_or_initialize_by({}).tap do |efr|
        efr.assign_attributes(approver: approver, role: role, message: '', created_user: creator, updated_user: creator)
        efr.save!
      end
    else
      event_follow_requests.destroy_all
    end
  end

  private

  attr_reader :event, :creator, :user, :approver, :role

  def event_follow_requests
    user.event_follow_requests.where(event: event, started_at: nil)
  end

  def current_role
    user.event_follows.find_by(event: event)&.role&.to_sym || :irrelevant
  end
end
