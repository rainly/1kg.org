class NeighborsController < ApplicationController
  before_filter :login_required
  
  def create
    neighbor = User.find(params[:user_id])
    myself = User.find(params[:my])
    
    @neighborhood = Neighborhood.new
    @neighborhood.user = myself
    @neighborhood.neighbor = neighbor
    @neighborhood.save!
    
    flash[:notice] = "加#{neighbor.login}为友邻"
    redirect_to user_url(neighbor)
  end
  
  def destroy
    neighbor = User.find(params[:user_id])
    myself = User.find(params[:id])
    
    @neighborhood = Neighborhood.delete_all(:user_id => myself.id, :neighbor_id => neighbor.id)
    
    flash[:notice] = "删除友邻#{neighbor.login}"
    redirect_to user_url(neighbor)
  end
  
  
end