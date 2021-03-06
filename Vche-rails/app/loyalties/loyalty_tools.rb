module LoyaltyTools
  module_function

  def user_is_owner?(event, user)
    event.owners.include?(user)
  end

  def user_is_backstage_member?(event, user)
    event.backstage_members.include?(user)
  end

  def user_is_creator?(event, user)
    event.created_user == user
  end

  def user_is_source?(event, user)
    event.official? ? user_is_backstage_member?(event, user) : user_is_creator?(event, user)
  end

  def user_is_primary_source?(event, user)
    event.official? ? user_is_owner?(event, user) : user_is_source?(event, user)
  end

  def event_allow_backstage?(event)
    event.visible? || Rails.application.config.x.vche.allow_private_backstage
  end

  def event_accessible?(event, user)
    case event&.visibility&.to_sym
    when :public, :shared
      true
    when :invite, :secret
      event.followers.include?(user) || user_is_creator?(event, user)
    else # :deleted
      false
    end
  end

  def user_accessible?(record, user)
    case record&.visibility&.to_sym
    when :public, :shared
      true
    when :invite, :secret
      record == user # TODO: user_follows
    else # :deleted
      false
    end
  end

  def password_login?
    Rails.application.config.x.vche.password_login
  end
end
