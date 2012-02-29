# -*- encoding : utf-8 -*-
class CollaboratorsController < ApplicationController
  before_filter :authenticate_user!

  before_filter :find_project
  before_filter :find_users
  before_filter :find_groups

  load_resource :project
  before_filter :authorize_collaborators

  def index
    redirect_to edit_project_collaborators_path(@project)
  end

  def show
  end

  def new
  end

  def edit
    if params[:id]
      @user = User.find params[:id]
      render :edit_rights and return
    end
  end

  def create
  end

  def update
    params['user'].keys.each { |user_id|
      role = params['user'][user_id]

      if relation = @project.relations.find_by_object_id_and_object_type(user_id, 'User')
        relation.update_attribute(:role, role)
      else
        relation = @project.relations.build(:object_id => user_id, :object_type => 'User', :role => role)
        relation.save!
      end
    } if params['user']

    params['group'].keys.each { |group_id|
      role = params['group'][group_id]
      if relation = @project.relations.find_by_object_id_and_object_type(group_id, 'Group')
        relation.update_attribute(:role, role)
      else
        relation = @project.relations.build(:object_id => user_id, :object_type => 'Group', :role => role)
        relation.save!
      end
    } if params['group']

    if @project.save
      flash[:notice] = t("flash.collaborators.successfully_changed")
    else
      flash[:error] = t("flash.collaborators.error_in_changing")
    end

    redirect_to edit_project_collaborators_path(@project)
  end

  def remove
    all_user_ids = []
    all_groups_ids = []

    params['user_remove'].keys.each { |user_id|
      all_user_ids << user_id if params['user_remove'][user_id] == ["1"]
    } if params['user_remove']
    params['group_remove'].keys.each { |group_id|
      all_group_ids << group_id if params['group_remove'][group_id] == ["1"]
    } if params['group_remove']

    all_user_ids.each do |user_id|
      u = User.find(user_id)
      Relation.by_object(u).by_target(@project).each {|r| r.destroy}
    end
    all_groups_ids.each do |group_id|
      g = Group.find(group_id)
      Relation.by_object(g).by_target(@project).each {|r| r.destroy}
    end

    redirect_to edit_project_collaborators_path(@project)
  end

  def add
    # TODO: Here is used Chelyabinsk method to display Flash messages.

    member = User.find(params['member_id']) if params['member_id'] && !params['member_id'].empty?
    group = Group.find(params['group_id']) if params['group_id'] && !params['group_id'].empty?

    flash[:notice], flash[:error], flash[:warning] = [], [], []

    [member, group].compact.each do |mem|
      if mem and @project.relations.exists?(:object_id => mem.id, :object_type => mem.class.to_s)
        flash[:warning] << [t('flash.collaborators.member_already_added'), mem.uname]
      end
      unless @project.relations.exists?(:object_id => mem.id, :object_type => mem.class.to_s)
        rel = @project.relations.build(:role => params[:role])
        rel.object = mem
        if rel.save
          flash[:notice] << [t('flash.collaborators.successfully_added'), mem.uname]
        else
          flash[:notice] << [t('flash.collaborators.error_in_adding'), mem.uname]
        end
      end
    end

    [:notice, :warning, :error].each do |k|
      if flash[k].size > 0
        flash[k] = flash[k].map{|i| (i.is_a? Array) ? sprintf(i.first, i.last) : i}.join('; ')
      else
        flash.delete k
      end
    end

    redirect_to(edit_project_collaborators_path(@project))
  end

  protected

    def find_project
      @project = Project.find params[:project_id]
    end

    def find_users
      @users = @project.collaborators#User.all
    end

    def find_groups
      @groups = @project.groups#Group.all
    end

    def authorize_collaborators
      authorize! :update, @project
    end
end
