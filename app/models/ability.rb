# -*- encoding : utf-8 -*-
# If rules goes one by one CanCan joins them by 'OR' sql operator
# If rule has multiple conditions CanCan joins them by 'AND' sql operator
# WARNING:
# - put cannot rules _after_ can rules and not before!
# - beware inner joins. Use sub queries against them!

class Ability
  include CanCan::Ability

  def initialize(user)
    user ||= User.new # guest user (not logged in)
    @user = user

    # Shared rights between guests and registered users
    can :forbidden, Platform
    # TODO remove because auth callbacks skipped
    can :auto_build, Project
    can [:publish_build, :status_build, :pre_build, :post_build, :circle_build, :new_bbdt], BuildList

    if user.guest? # Guest rights
      can :create, User
      can [:create, :show_message], RegisterRequest
    else # Registered user rights
      if user.admin?
        can :manage, :all
        cannot :destroy, Subscribe
        cannot :create, Subscribe
        cannot :create, RegisterRequest
        cannot :approve, RegisterRequest, :approved => true
        cannot :reject, RegisterRequest, :rejected => true
        cannot [:owned, :related], BuildList
      end

      if user.user?
        can [:show, :autocomplete_user_uname], User
        can [:edit, :update, :private], User, :id => user.id

        can [:show, :update], Settings::Notifier, :user_id => user.id

        can [:read, :create, :autocomplete_group_uname], Group
        can [:update, :manage_members], Group do |group|
          group.objects.exists?(:object_type => 'User', :object_id => user.id, :role => 'admin') # or group.owner_id = user.id
        end
        can :destroy, Group, :owner_id => user.id

        can :create, Project
        can :read, Project, :visibility => 'open'
        can :read, Project, :owner_type => 'User', :owner_id => user.id
        can :read, Project, :owner_type => 'Group', :owner_id => user.group_ids
        can(:read, Project, read_relations_for('projects')) {|project| local_reader? project}
        can(:write, Project) {|project| local_writer? project} # for grack
        can([:update, :sections, :manage_collaborators], Project) {|project| local_admin? project}
        can(:fork, Project) {|project| can? :read, project}
        can(:destroy, Project) {|project| owner? project}
        can :remove_user, Project

        # TODO: Turn on AAA when it will be updated
        #can :create, AutoBuildList
        #can [:index, :destroy], AutoBuildList, :project_id => user.own_project_ids

        can [:read, :owned], BuildList, :user_id => user.id
        can :read, BuildList, :project => {:visibility => 'open'}
        can [:read, :related], BuildList, :project => {:owner_type => 'User', :owner_id => user.id}
        can [:read, :related], BuildList, :project => {:owner_type => 'Group', :owner_id => user.group_ids}
        can(:read, BuildList, read_relations_for('build_lists', 'projects')) {|build_list| can? :read, build_list.project}
        can(:create, BuildList) {|build_list| build_list.project.is_rpm && can?(:write, build_list.project)}
        can(:publish, BuildList) {|build_list| build_list.can_publish? && can?(:write, build_list.project)}
        can(:cancel, BuildList) {|build_list| build_list.can_cancel? && can?(:write, build_list.project)}

        can :read, Platform, :visibility => 'open'
        can :read, Platform, :owner_type => 'User', :owner_id => user.id
        can :read, Platform, :owner_type => 'Group', :owner_id => user.group_ids
        can(:read, Platform, read_relations_for('platforms')) {|platform| local_reader? platform}
        can([:update, :build_all], Platform) {|platform| local_admin? platform}
        can([:freeze, :unfreeze, :destroy], Platform) {|platform| owner? platform}
        can :autocomplete_user_uname, Platform

        can :read, Repository, :platform => {:visibility => 'open'}
        can :read, Repository, :platform => {:owner_type => 'User', :owner_id => user.id}
        can :read, Repository, :platform => {:owner_type => 'Group', :owner_id => user.group_ids}
        can(:read, Repository, read_relations_for('repositories', 'platforms')) {|repository| local_reader? repository.platform}
        can([:create, :update, :projects_list, :add_project, :remove_project], Repository) {|repository| local_admin? repository.platform}
        can([:change_visibility, :settings, :destroy], Repository) {|repository| owner? repository.platform}

        can :read, Product, :platform => {:owner_type => 'User', :owner_id => user.id}
        can :read, Product, :platform => {:owner_type => 'Group', :owner_id => user.group_ids}
        can(:manage, Product, read_relations_for('products', 'platforms')) {|product| local_admin? product.platform}
        can(:create, ProductBuildList) {|pbl| pbl.product.can_build? and can?(:update, pbl.product)}
        can(:destroy, ProductBuildList) {|pbl| can?(:destroy, pbl.product)}
      
        can [:read, :platforms], Category

        can [:read, :create], PrivateUser, :platform => {:owner_type => 'User', :owner_id => user.id}
        can [:read, :create], PrivateUser, :platform => {:owner_type => 'Group', :owner_id => user.group_ids}

        # can :read, Issue, :status => 'open'
        can :read, Issue, :project => {:visibility => 'open'}
        can :read, Issue, :project => {:owner_type => 'User', :owner_id => user.id}
        can :read, Issue, :project => {:owner_type => 'Group', :owner_id => user.group_ids}
        can(:read, Issue, read_relations_for('issues', 'projects')) {|issue| can? :read, issue.project rescue nil}
        can(:create, Issue) {|issue| can? :write, issue.project}
        can([:update, :destroy], Issue) {|issue| issue.user_id == user.id or local_admin?(issue.project)}
        cannot :manage, Issue, :project => {:has_issues => false} # switch off issues

        can(:create, Comment) {|comment| can? :read, comment.project}
        can(:update, Comment) {|comment| comment.user_id == user.id or local_admin?(comment.project || comment.commentable.project)}
        cannot :manage, Comment, :commentable_type => 'Issue', :commentable => {:project => {:has_issues => false}} # switch off issues
        cannot :manage, RegisterRequest
      end

      # Shared cannot rights for all users (registered, admin)
      cannot :destroy, Platform, :platform_type => 'personal'
      cannot :destroy, Repository, :platform => {:platform_type => 'personal'}
      cannot :fork, Project, :owner_id => user.id, :owner_type => user.class.to_s
      cannot :destroy, Issue

      can :create, Subscribe do |subscribe|
        !subscribe.subscribeable.subscribes.exists?(:user_id => user.id)
      end
      can :destroy, Subscribe do |subscribe|
        subscribe.subscribeable.subscribes.exists?(:user_id => user.id) && user.id == subscribe.user_id
      end
    end
  end

  # TODO group_ids ??
  def read_relations_for(table, parent = nil)
    key = parent ? "#{parent.singularize}_id" : 'id'
    parent ||= table
    ["#{table}.#{key} IN (
      SELECT target_id FROM relations WHERE relations.target_type = ? AND
      (relations.object_type = 'User' AND relations.object_id = ? OR
       relations.object_type = 'Group' AND relations.object_id IN (?)))", parent.classify, @user, @user.group_ids]
  end

  def relation_exists_for(object, roles)
    object.relations.exists?(:object_id => @user.id, :object_type => 'User', :role => roles) or
    object.relations.exists?(:object_id => @user.group_ids, :object_type => 'Group', :role => roles)
  end

  def local_reader?(object)
    relation_exists_for(object, %w{reader writer admin}) or owner?(object)
  end

  def local_writer?(object)
    relation_exists_for(object, %w{writer admin}) or owner?(object)
  end

  def local_admin?(object)
    relation_exists_for(object, 'admin') or owner?(object)
  end

  def owner?(object)
    object.owner == @user or @user.own_groups.include?(object.owner)
  end
end
