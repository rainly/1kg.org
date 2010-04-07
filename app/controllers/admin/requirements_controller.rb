class Admin::RequirementsController < Admin::BaseController
  before_filter :find_requirement_type
  
  def index
    @requirements = @type.requirements.find :all, :order => "created_at desc"
    
    if @type.exchangable?
      render :action => "exchangable_list"
    else
      render :action => "non_exchangable_list"
    end
  end
  
  def new
    @requirement = Requirement.new
  end
  
  def create
    @requirement = Requirement.new(params[:requirement])
    #@requirement.agree_feedback_terms = true
    @requirement.requirement_type = @type
    @requirement.save!
    flash[:notice] = "新需求创建成功"
    redirect_to admin_requirement_type_requirements_url(@type)
  end
  
  def edit
    @requirement = Requirement.find(params[:id])
  end
  
  def approve
    @requirement = Requirement.find(params[:id])
    @requirement.update_attribute(:validated, true)
    @requirement.update_attribute(:status, 1)
    redirect_to admin_requirement_type_requirements_url(@requirement.requirement_type)
  end
  
  def reject
    @requirement = Requirement.find(params[:id])
    @requirement.update_attribute(:validated, false)
    
    redirect_to admin_requirement_type_requirements_url(@requirement.requirement_type)
  end
  
  def update
    @requirement = Requirement.find(params[:id])
    @requirement.update_attributes!(params[:requirement])
    flash[:notice] = "Buck 更新成功"
    redirect_to admin_requirement_type_requirements_url
  end
  
  def destroy
    @requirement = Requirement.find(params[:id])
    @requirement.destroy
    flash[:notice] = "Buck 删除成功"
    redirect_to admin_requirement_type_requirements_url
  end
  
  def show
    @requirement = Requirement.find(params[:id])
    @donations = @requirement.donations.find :all, :include => [:user, :school]
    
    respond_to do |format|
      format.html
      format.csv do
        csv_string = FasterCSV.generate do |csv|
          @donations.each do |donation|
            csv << donation.code
          end
        end
        
        send_data csv_string,
                  :type => 'text/csv; charset=iso-8859-1; header=present',
                  :disposition => "attachment; filename=passwords.csv"
      end
    end
  end
  
  private
  def find_requirement_type
    @type = RequirementType.find(params[:requirement_type_id])
  end
  
end