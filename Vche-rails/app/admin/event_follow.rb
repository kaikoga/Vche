# == Schema Information
#
# Table name: event_follows
#
#  id         :bigint           not null, primary key
#  user_id    :bigint           not null
#  event_id   :bigint           not null
#  role       :string(255)
#  created_at :datetime         not null
#  updated_at :datetime         not null
#
# Indexes
#
#  index_event_follows_on_event_id              (event_id)
#  index_event_follows_on_user_id               (user_id)
#  index_event_follows_on_user_id_and_event_id  (user_id,event_id) UNIQUE
#
# Foreign Keys
#
#  fk_rails_...  (event_id => events.id)
#  fk_rails_...  (user_id => users.id)
#
ActiveAdmin.register EventFollow do
  menu parent: :user
end
