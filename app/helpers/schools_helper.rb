module SchoolsHelper
  def radio_choice(form, object)
    [[0,"无"], [1,"有"], [2, "未知"]].collect {|r| form.radio_button(object, r[0]) + r[1]}
  end
  
  def radio_value(value)
    result = %w(没有 有 未知)
    value.blank? ? "未知" : result[value]
  end
  
  def validate_for_human(school)
    if school.validated?
      if school.validator
        "#{school.validated_at.to_date}由#{link_to school.validator.login, user_url(school.validator)}验证"
      else
        "#{school.validated_at.to_date}通过验证"
      end
    else
      if school.validated_at.blank?
        "<span class=\"required\">学校信息未验证</span>"
      elsif school.validator
        "<span class=\"required\">#{school.validated_at.to_date}由#{link_to school.validator.login, user_url(school.validator)}取消验证</span>"
      elsif school.validated_at && !school.validator.blank?
        "<span class=\"required\">#{school.validated_at.to_date}取消验证</span>"
      end

    end
  end
  
  def edit_school_position_path(school)
    edit_school_path(school, :step => 'position')
  end
  
  def render_school_main_photo(school)
    html = ''
    if school.main_photo
      html += image_tag(school.main_photo.public_filename(:small))
    else
      html += image_tag(image_path('/images/default_school.jpg'), :width => "200")
    end
    html
  end
  
  def needs_check_box(form, tag, options, value)
    # 对秀秀和多背一公斤显示文本框模式
    if current_user.id == 31 || current_user.id == 1
      form.text_field tag, :size => 60
    else
      options.map do |option|
        included = value.nil? ? false : value.include?(option)
        check_box_tag(tag, option, included, :onchange => "update_needs('#{tag.to_s}')", :class => "#{tag}_needs") + 
        form.label(tag, option, {:class => 'checkbox_label'})
      end.join + form.hidden_field(tag, :id => "#{tag}_needs")
    end
  end
  
  def karma_star(karma)
    #要加上活跃度评星算法
    if karma == nil
      count = 0
    elsif karma < 10
      count = 0
    elsif karma < 30
      count = 1
    elsif karma < 60
      count = 2
    elsif karma < 150
      count = 3
    elsif karma < 300
      count = 4
    else
      count = 5
    end
    html = "<span title='活跃度:#{karma}'>" + '<img src="/images/star.png" alt="" class="stars"/>'*count + '<img src="/images/star_gary.png" class="stars"/>'*(5-count) + '</span>'
  end
  
  def link_to_needs(needs)
    unless needs.blank? 
      needs.split(' ').map do |need|
        link_to need, tag_path(:tag => need),:class => "need_tag"
      end.join(' ')
    else
      ""
    end
  end
  
  def needlist(school)
    return '' unless school.need
    list = [school.need.book,school.need.medicine,school.need.stationary,school.need.sport,school.need.cloth,school.need.accessory,school.need.course,school.need.teacher,school.need.other]
    list.map{|n| link_to_needs(n) }.join('')
  end
end