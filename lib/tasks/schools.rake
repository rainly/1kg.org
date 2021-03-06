require 'fastercsv'
require 'hpricot'
require 'open-uri'
require 'cgi'
require 'gmap'

include GMap

namespace :schools do
  # desc "生成学校需求的Tag"
  # task :generate_need_tags => :environment do
  #   # generate content
  #   School.available.each do |school|
  #     need = school.need
  #     if need
  #       need.tags.clear
  #       tag_list = [need.urgency, need.book, need.stationary, need.sport, need.cloth, need.accessory, need.course, need.teacher].join(',')
  #       tag_list.gsub!(/,/, ' ')
  #       tag_list.gsub!(/，/, ' ')
  #       tag_list.gsub!(/、/, ' ')
  #       tag_list.gsub!(/。/, ' ')
  #       tag_list.gsub!(/：/, ' ')
  #       tag_list.gsub!(/；/, ' ')
  #       need.tag_list = tag_list
  #       need.save(false)
  #     end
  #     
  #     $stdout.putc('.')
  #     $stdout.flush
  #   end
  #   puts ''
  #   puts "Successful."
  # end
  
  desc "删除失效的大使权限"
  task :role_delete => :environment do
    roles = Role.all.map{|r| r if r.identifier =~ /^roles.school.moderator./}.compact
    roles.each do |r|
      if School.find(:first,:conditions => {:id => (r.identifier).split('.').last.to_i}) == nil
        r.delete 
        $stdout.putc('.')
        $stdout.flush
      end
    end
  end  
  
  desc "删除失效的用户动态"
  task :visited_delete => :environment do
    Visited.all.each do |r|
      if School.find(:first,:conditions => {:id => r.school_id}) == nil
        r.delete 
        $stdout.putc('.')
        $stdout.flush
      end
    end
  end  

  
  desc "count schools' karma(popularity)"
  task :popularity => :environment do
    schools = School.validated
    puts "学校总数：#{schools.size}"
    
    schools.each do |school|
      karma = 0
      # 活动 20s/个 （另外活动回复 1/s + 参加 2/s）
      school.activities.each do |activity|
        karma += activity.comments.count * 1
        karma += activity.participators.count * 2
        karma += 20
      end
      # 照片 2s/张
      karma += school.photos.count * 2
      # 分享 10s/篇 (另外 分享回复 1s/个)
      school.shares.each do |share|
        karma += share.comments.count * 1
        karma += 10
      end
      # 话题回复 1s/个 学校话题 2s/个
      school.discussion.board.topics.each do |topic|
        karma += topic.posts.count * 1
        karma += 2
      end
      # 去过用户 4s/人  要去 2s/人  关注  2s/人
      karma += school.visitors.count * 4
      karma += school.interestings.count * 2
      karma += school.wannas.count * 2
      # 学校大使 10s/人
      karma += User.moderators_of(school).size * 10
      
      # 更新学校活跃度
      school.update_attribute(:karma, karma) #unless school.karma == karma

      # 更新学校当月平均活跃度
      #last_month_karma = karma - school.snapshots.find_by_created_on(Date.today - 1.month).karma rescue karma
      #puts last_month_karma
      #school.update_attribute(:last_month_karma, last_month_karma)
      #puts "#{school.title}: #{last_month_karma}" unless karma == 0
    end
  end 
  
  desc "初始化Counter cache"
  task :counter_cache => :environment do
    User.all.each do |user|
      puts user.login
      user.posts_count = user.posts.count
      user.shares_count = user.shares.count
      user.guides_count = user.guides.count
      user.topics_count = user.topics.count
      user.save(false)
    end
  end
  
  desc "import all schools to db/schools.csv"
  task :export => :environment do
    file = File.open("#{RAILS_ROOT}/db/schools.csv", 'w')
    
    csv_string = FasterCSV.generate do |csv|
      # generate header
      csv << ['id', 'name', 'address', 'introduction', 'times', 'shares', 'last_update']
      
      # generate content
      School.avaiable.each do |school|
        last_share = school.shares.last
        last_update = last_share.nil? ? '无' : "#{last_share.updated_at.to_date} by #{last_share.user.login}"
        introduction = "年级：#{school.level_amount}，班级：#{school.class_amount}，老师：#{school.teacher_amount}，学生：#{school.student_amount}"
        csv << [school.id, school.title, school.basic.address, introduction, school.visitors.count, school.shares.count, last_update]
        $stdout.putc('.')
        $stdout.flush
      end
    end
    
    file.write(csv_string)
    file.close
    puts ''
    puts "#{School.count} schools updated."
  end
  
  # desc "import meta schools from db/schools.csv"
  # task :import => :environment do
  #   file = File.open("#{RAILS_ROOT}/db/schools.csv", 'r')
  #   file.each_line do |line|
  #     attributes = line.split(',')
  #     
  #     address = attributes[1]
  #     city = ''
  #     if address.include?('省') || address.include?('自治区') || address.include?('特别行政区')
  #       city = address.gsub!(/省(.*?)$/, '')
  #       city = address.gsub!(/自治区(.*?)$/, '')
  #       city = address.gsub!(/特别行政区(.*?)$/, '')
  #     else
  #       city = address.gsub!(/市(.*?)$/, '')
  #     end
  #     geo = Geo.find_by_name(city) || Geo.first
  #     
  #     school = School.new(:title => attributes[4], :meta => true, :validated => false, :geo_id => geo)
  #     school.basic = SchoolBasic.new(:address => attributes[1], 
  #                                     :zipcode => attributes[6], 
  #                                     :master => attributes[3], 
  #                                     :telephone => attributes[2])
  #     
  #     if school.save
  #       puts school.id 
  #     else
  #       puts school.errors.full_messages
  #     end
  #   end
  # end

  desc "generate a json file used for google map"
  task :to_json => :environment do
    require 'json'
    schools = School.validated
    schools_json = []
    schools.each do |school|
      if school.basic.blank?
        puts "#{school.id} -- #{school.title}"
        next
      end
      schools_json << {:i => school.id,
                       :t => school.icon_type,
                       :n => school.title,
                       :a => school.basic.latitude,
                       :o => school.basic.longitude
                      }
    end
    
    file = File.open("#{RAILS_ROOT}/public/schools.json", 'w')
    file.write('var schools =')
    file.write schools_json.to_json
    file.close
  end
  
  # desc "check if school's discussion exist"
  # task :discussion_check => :environment do
  #   schools = School.find(:all)
  #   schools.each do |s|
  #     puts "#{s.title}(#{s.id}) has not discussion" unless s.discussion
  #     puts "#{s.discussion.id} has not board" unless s.discussion.board
  #   end
  # 
  # end
  
  # desc "initial school validated_at column"
  # task :initial_validated_at => :environment do
  #   puts "-- begin initial schools' validated_at column"
  #   schools = School.validated.find :all
  #   schools.each do |s|
  #     s.update_attributes!(:validated_at => s.created_at)
  #   end
  #   puts "-- finish fullfill the validated_at column for validated schools"
  # end
  
  # desc "check school's moderator, create if not exist"
  # task :check_moderator => :environment do
  #   schools = School.find :all
  #   schools.each do |school|
  #     role = Role.find_by_identifier("roles.school.moderator.#{school.id}")
  #     if role.nil?
  #       puts school.title
  #       Role.create(:identifier => "roles.school.moderator.#{school.id}")
  #     end
  #   end
  # end
  
  # desc "将提交者作为学校爱心大使"
  # task :set_submitor_as_school_lover => :environment do
  #   schools = School.all
  #   schools.each do |s|
  #     submitor = s.user
  #     role = Role.find_by_identifier("roles.school.moderator.#{s.id}")
  #     if role.nil?
  #       puts "#{s.id} - #{s.title} 没有爱心大使权限"
  #       next
  #     else
  #       submitor.roles << role unless submitor.roles.include?(role)
  #       puts "设置 #{submitor.login} 为 #{s.title} 的爱心大使"
  #     end
  #   end
  # end
    
  namespace :coordinates do
    desc "generate coordinates for all schools"
    task :generate => :environment do
      School.all.each do |school|
        coordinates = find_coordinates_by_address(school.basic.address)
        school.basic.longitude = coordinates[0]
        school.basic.latitude  = coordinates[1]
        school.basic.save(false)
        puts school.title + ':' + school.basic.longitude + ',' + school.basic.latitude
      end
    end
  end
end

namespace :geo do
  namespace :coordinates do
    desc "generate coordinates for all geos"
    task :generate => :environment do
      Geo.all.each do |geo|
        coordinates = find_coordinates_by_address(geo.name)
        geo.longitude = coordinates[0]
        geo.latitude = coordinates[1]
        geo.save(false)
        puts geo.name + ':' + geo.longitude + ',' + geo.latitude
      end
    end
  end
end

