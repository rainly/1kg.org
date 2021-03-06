class MiscController < ApplicationController
  
  def index
    @page_title = "首页"
    @school_count = School.validated.size
    @activity_count = Activity.ongoing.size
    logged_in?? public_look : render(:action => "welcome")
  end
  
  def public_look
    @page_title = "首页"
    @school_count = School.validated.size
    @activity_count = Activity.ongoing.size
    @new_schools = School.find(:all,:limit => 4,:order => "created_at desc")
    @hot_activities = Activity.ongoing.find(:all,:limit => 4,:order => "participations_count desc" ,:conditions => {:created_at => 1.month.ago..Time.now})
    @recent_shares = Share.recent_shares
    # 网站公告
    @bulletins = Bulletin.recent
    @visits = Visited.latestvisit
    @wannas = Visited.latestwanna
    render :action => "index"
  end
    
  def show_page
    #for static page
    @page = Page.find_by_slug(params[:slug]) or raise ActiveRecord::RecordNotFound
  end

end