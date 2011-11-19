class AutoBuildListsController < ApplicationController
  before_filter :authenticate_user!, :except => :auto_build
  before_filter :find_project, :only => :create
  before_filter :find_auto_build_list, :only => :destroy

  authorize_resource
  skip_authorize_resource :only => :create
  
  def index
    projects = Project.where(:owner_id => current_user.id, :owner_type => 'User').order('name ASC')
    @projects_not_automated = projects.automateable.paginate(:page => params[:not_automated_page])
    @projects_not_automated = @projects_not_automated.where(:name => params[:name]) unless params[:name].blank?

    @projects_already_automated = projects.select('projects.*, auto_build_lists.id auto_build_lists_id').
                                  joins(:auto_build_lists).paginate(:page => params[:already_automated_page])
  end
  
  #def new
  #  @auto_build_list = AutoBuildList.new
  #  # Now user can create auto_build_list only for personal repository and i586 arch.
  #  @bpls = Platform.where(:id => current_user.personal_platform.id)
  #  @pls = Platform.where(:id => current_user.personal_platform.id)
  #  @archs = Arch.where(:name => 'i386')
  #end
  
  def create
    authorize :build, @project
    #@auto_build_list = AutoBuildList.new(params[:auto_build_list])
    
    @auto_build_list = AutoBuildList.new(
      :bpl_id => Platform.find_by_unixname('mandriva2011').try(:id),
      :pl_id => current_user.personal_platform.id,
      :arch_id => Arch.find_by_name('i586').id,
      :project_id => params[:project_id]
    )
    
    if @auto_build_list.save
      redirect_to auto_build_lists_path(), :notice => t('flash.auto_build_list.success')
    else
      #render :action => 'new'
      redirect_to auto_build_lists_path, :notice => t('flash.auto_build_list.failed')
    end
  end

  def destroy
    if @auto_build_list.destroy
      flash[:notice] = t('flash.auto_build_list.cancel')
    else
      flash[:notice] = t('flash.auto_build_list.cancel_failed')
    end
    redirect_to auto_build_lists_path
  end

protected

  def find_project
    @project = Project.find(params[:project_id])
  end

  def find_auto_build_list
    @auto_build_list = AutoBuildList.find(params[:id])
  end

end
