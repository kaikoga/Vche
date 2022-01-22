class AddEditorFieldsToEventFollowRequests < ActiveRecord::Migration[6.1]
  def change
    add_column :event_follow_requests, :created_user_id, :bigint, foreign_key: { to_table: :users }, after: :state
    add_column :event_follow_requests, :updated_user_id, :bigint, foreign_key: { to_table: :users }, after: :created_user_id
  end
end
