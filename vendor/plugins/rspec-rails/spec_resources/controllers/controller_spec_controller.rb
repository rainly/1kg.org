class ControllerSpecController < ActionController::Base
  before_filter :raise_error, :only => :action_with_skipped_before_filter
  
  def raise_error
    raise "from a before filter"
  end
  
  skip_before_filter :raise_error
  
  if ['edge','2.0.0'].include?(ENV['RSPEC_RAILS_VERSION'])
    set_view_path [File.join(File.dirname(__FILE__), "..", "views")]
  else
    set_view_path File.join(File.dirname(__FILE__), "..", "views")
  end
  
  def some_action
    render :template => "template/that/does/not/actually/exist"
  end
  
  def action_with_template
    render :template => "controller_spec/action_with_template"
  end
  
  def action_which_sets_flash
    flash[:flash_key] = "flash value"
    render :text => ""
  end
  
  def action_which_gets_session
    raise "expected #{params[:session_key].inspect}\ngot #{session[:session_key].inspect}" unless (session[:session_key] == params[:expected])
    render :text => ""
  end
  
  def action_which_sets_session
    session[:session_key] = "session value"
  end
      
  def action_which_gets_cookie
    raise "expected #{params[:expected].inspect}, got #{cookies[:cookie_key].inspect}" unless (cookies[:cookie_key] == params[:expected])
    render :text => ""
  end
      
  def action_which_sets_cookie
    cookies['cookie_key'] = params[:value]
    render :text => ""
  end
      
  def action_with_partial
    render :partial => "controller_spec/partial"
  end
  
  def action_with_partial_with_object
    render :partial => "controller_spec/partial", :object => params[:thing]
  end
  
  def action_with_partial_with_locals
    render :partial => "controller_spec/partial", :locals => {:thing => params[:thing]}
  end
  
  def action_with_errors_in_template
    render :template => "controller_spec/action_with_errors_in_template"
  end

  def action_setting_the_assigns_hash
<<<<<<< HEAD:vendor/plugins/rspec-rails/spec_resources/controllers/controller_spec_controller.rb
=======
    assigns['direct_assigns_key'] = :direct_assigns_key_value
>>>>>>> c0ecd1809fb41614ff2905f5c6250ede5f190a92:vendor/plugins/rspec-rails/spec_resources/controllers/controller_spec_controller.rb
    @indirect_assigns_key = :indirect_assigns_key_value
  end
  
  def action_setting_flash_after_session_reset
    reset_session
    flash[:after_reset] = "available"
  end
  
  def action_setting_flash_before_session_reset
    flash[:before_reset] = 'available'
    reset_session
  end
  
  def action_with_render_update
    render :update do |page|
      page.replace :bottom, 'replace_me',
                            :partial => 'non_existent_partial'
    end
  end
  
  def action_with_skipped_before_filter
    render :text => ""
  end
<<<<<<< HEAD:vendor/plugins/rspec-rails/spec_resources/controllers/controller_spec_controller.rb
  
  def action_that_assigns_false_to_a_variable
    @a_variable = false
    render :text => ""
  end
=======
>>>>>>> c0ecd1809fb41614ff2905f5c6250ede5f190a92:vendor/plugins/rspec-rails/spec_resources/controllers/controller_spec_controller.rb
end

class ControllerInheritingFromApplicationControllerController < ApplicationController
  def action_with_inherited_before_filter
    render :text => ""
  end
end