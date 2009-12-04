# == Schema Information
#
# Table name: posts
#
#  id                  :integer(4)      not null, primary key
#  topic_id            :integer(4)      not null
#  user_id             :integer(4)      not null
#  body_html           :text
#  created_at          :datetime
#  updated_at          :datetime
#  last_modified_at    :datetime
#  last_modified_by_id :integer(4)
#  deleted_at          :datetime
#  clean_html          :text
#

# == Schema Information
# Schema version: 20090430155946
#
# Table name: posts
#
#  id                  :integer(4)      not null, primary key
#  topic_id            :integer(4)      not null
#  user_id             :integer(4)      not null
#  body                :text
#  body_html           :text
#  created_at          :datetime
#  updated_at          :datetime
#  last_modified_at    :datetime
#  last_modified_by_id :integer(4)
#  deleted_at          :datetime
#

class Post < ActiveRecord::Base
  include BodyFormat
  
  belongs_to :topic, :counter_cache => 'posts_count'
  belongs_to :user
  
  acts_as_paranoid
  
  #before_save :format_content
  after_create :update_last_replied
  
  named_scope :available, :conditions => {:deleted_at => nil}
  
  def editable_by(user)
    user != nil && (self.user_id == user.id || self.topic.board.has_moderator?(user) || user.admin?)
  end
  
  def format_content
    body.strip! if body.respond_to?(:strip!)
    self.body_html = body.blank? ? '' : formatting_body_html(body)
  end
  
  private

  def update_last_replied
    self.topic.last_replied_at = self.created_at
    self.topic.last_replied_by_id = self.user_id
    self.topic.save(false)
  end
  
  # def update_posts_count
  #   self.topic.update_attributes!(:posts_count => Post.count(:all, :conditions => {:topic_id => self.topic.id}),
  #                                 :last_replied_at => self.created_at,
  #                                 :last_replied_by_id => self.user_id)
  # end
  
end
