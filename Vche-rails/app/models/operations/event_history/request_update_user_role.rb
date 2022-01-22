class Operations::EventHistory::RequestUpdateUserRole
  include Operations::Operation

  class Outsider < StandardError; end

  def initialize(event_history:, creator:, user:, approver:, role:)
    @event_history = event_history
    @creator = creator
    @user = user
    @approver = approver
    @role = role&.to_sym
  end

  def validate
    raise ArgumentError if role == :irrelevant
    raise Outsider unless EventAttendance.backstage_role?(role) || EventAttendance.backstage_role?(current_role)
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

  attr_reader :event_history, :creator, :user, :approver, :role

  def event_follow_requests
    user.event_follow_requests.where(event: event_history.event, started_at: event_history.started_at)
  end

  def current_role
    user.event_attendances.for_event_history(event_history).first&.role&.to_sym || :irrelevant
  end
end
