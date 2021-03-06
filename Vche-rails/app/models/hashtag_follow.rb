# == Schema Information
#
# Table name: hashtag_follows
#
#  id         :bigint           not null, primary key
#  user_id    :bigint           not null
#  hashtag    :string(255)
#  role       :string(255)
#  created_at :datetime         not null
#  updated_at :datetime         not null
#
# Indexes
#
#  index_hashtag_follows_on_user_id                       (user_id)
#  index_hashtag_follows_on_user_id_and_hashtag_and_role  (user_id,hashtag,role) UNIQUE
#
# Foreign Keys
#
#  fk_rails_...  (user_id => users.id)
#
class HashtagFollow < ApplicationRecord
  include Enums::Role
end
