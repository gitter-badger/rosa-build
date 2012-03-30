# -*- encoding : utf-8 -*-
class PlatformsController < ApplicationController
  before_filter :authenticate_user!
  before_filter :find_platform, :only => [:clone, :edit, :destroy, :members]
  before_filter :get_paths, :only => [:new, :create, :clone]
  
  load_and_authorize_resource
  autocomplete :user, :uname

  def build_all
    @platform.delay.build_all(current_user)

    redirect_to(platform_path(@platform), :notice => t("flash.platform.build_all_success"))
  end

  def index
    @platforms = @platforms.accessible_by(current_ability, :related).paginate(:page => params[:page], :per_page => 20)
  end

  def show
    @platform = Platform.find params[:id], :include => :repositories
    #@repositories = @platform.repositories
    #@members = @platform.members.uniq
  end

  def new
    @platform = Platform.new
    @admin_uname = current_user.uname
    @admin_id = current_user.id
  end

  def edit
    @admin_id = @platform.owner.id
    @admin_uname = @platform.owner.uname
  end

  def create
    @platform = Platform.new params[:platform]
    @admin_id = params[:admin_id]
    @admin_uname = params[:admin_uname]
    @platform.owner = @admin_id.blank? ? get_owner : User.find(@admin_id)

    if @platform.save
      flash[:notice] = I18n.t("flash.platform.created")
      redirect_to @platform
    else
      flash[:error] = I18n.t("flash.platform.create_error")
      render :action => :new
    end
  end

  def update
    @admin_id = params[:admin_id]
    @admin_uname = params[:admin_uname]

    if @platform.update_attributes(
      :owner => @admin_id.blank? ? get_owner : User.find(@admin_id),
      :description => params[:platform][:description],
      :released => params[:platform][:released]
    )
      flash[:notice] = I18n.t("flash.platform.saved")
      redirect_to @platform
    else
      flash[:error] = I18n.t("flash.platform.save_error")
      render :action => :new
    end
  end

  def clone
    @cloned = Platform.new
    @cloned.name = @platform.name + "_clone"
    @cloned.description = @platform.description + "_clone"
  end

  def make_clone
    @cloned = @platform.full_clone params[:platform].merge(:owner => current_user)
    if @cloned.persisted?
      flash[:notice] = I18n.t("flash.platform.clone_success")
      redirect_to @cloned
    else
      flash[:error] = @cloned.errors.full_messages.join('. ')
      render 'clone'
    end
  end

  def destroy
    @platform.delay.destroy if @platform

    flash[:notice] = t("flash.platform.destroyed")
    redirect_to platforms_path
  end

  def members
    @members = @platform.members.order('name')
  end

  def remove_members
    all_user_ids = params['user_remove'].inject([]) {|a, (k, v)| a << k if v.first == '1'; a}
    all_user_ids.each do |uid|
      Relation.by_target(@platform).where(:object_id => uid, :object_type => 'User').each{|r| r.destroy}
    end
    redirect_to members_platform_path(@platform)
  end

  def remove_member
    u = User.find(params[:member_id])
    Relation.by_object(u).by_target(@platform).each{|r| r.destroy}

    redirect_to members_platform_path(@platform)
  end

  def add_member
    if params[:member_id].present?
      member = User.find(params[:member_id])
      if @platform.relations.exists?(:object_id => member.id, :object_type => member.class.to_s) or @platform.owner == member
        flash[:warning] = t('flash.platform.members.already_added', :name => member.uname)
      else
        rel = @platform.relations.build(:role => 'admin')
        rel.object = member
        if rel.save
          flash[:notice] = t('flash.platform.members.successfully_added', :name => member.uname)
        else
          flash[:error] = t('flash.platform.members.error_in_adding', :name => member.uname)
        end
      end
    end
    redirect_to members_platform_url(@platform)
  end

  protected
    def get_paths
      if params[:user_id]
        @user = User.find params[:user_id]
        @platforms_path = user_platforms_path @user
        @new_platform_path = new_user_platform_path @user
      elsif params[:group_id]
        @group = Group.find params[:group_id]
        @platforms_path = group_platforms_path @group
        @new_platform_path = new_group_platform_path @group
      else
        @platforms_path = platforms_path
        @new_platform_path = new_platform_path
      end
    end

    def find_platform
      @platform = Platform.find params[:id]
    end
end
