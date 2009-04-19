class Share < ActiveRecord::Base
  belongs_to :user
  belongs_to :geo
  belongs_to :activity
  belongs_to :school
  has_many :comments, :class_name => "ShareComment", :foreign_key => "type_id", :dependent => :destroy
  
  validates_presence_of :geo_id, :message => "请选择一个和你的分享有关的城市"
  validates_presence_of :title,  :message => "请起个题目"
  
  named_scope :available, :conditions => ["hidden=?", false]
  
  after_create :initial_last_replied
  
  def self.recent_shares
    available.find(:all, :order => "updated_at desc, comments_count desc",
                         :limit => 10,
                         :select => "id, user_id, title, hits, comments_count, created_at")
  end
  
  def moderated_by?(user)
    (! user.blank?) and (user_id == user.id or user.has_role?("roles.admin"))
  end
  
  def self.archives
    date_func = "extract(year from created_at) as year,extract(month from created_at) as month"
    
    counts = Share.find_by_sql(["select count(*) as count, #{date_func} from shares where created_at < ? group by year,month order by year asc,month asc",Time.now])
    
    sum = 0
    result = counts.map do |entry|
      sum += entry.count.to_i
      {
        :name => entry.year + "年" + entry.month + "月",
        :month => entry.month.to_i,
        :year => entry.year.to_i,
        :delta => entry.count,
        :sum => sum
      }
    end
    return result.reverse
  end
  
  private
  def initial_last_replied
    self.update_attributes!(:last_replied_at => self.created_at, :last_replied_by_id => self.user_id)
  end
  
end