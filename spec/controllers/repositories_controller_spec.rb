require 'spec_helper'
#require 'shared_examples/repositories_controller'

describe RepositoriesController do
	before(:each) do
    @repository = Factory(:repository)
    @personal_repository = Factory(:personal_repository)
    @platform = Factory(:platform)
    @project = Factory(:project)
    @another_user = Factory(:user)
    @create_params = {:repository => {:name => 'pro', :description => 'pro2'}, :platform_id => @platform.id}
	end

	context 'for guest' do
    [:index, :create].each do |action|
      it "should not be able to perform #{ action } action" do
        get action
        response.should redirect_to(new_user_session_path)
      end
    end

    [:show, :new, :add_project, :remove_project, :destroy].each do |action|
      it "should not be able to perform #{ action } action" do
        get action, :id => @repository.id
        response.should redirect_to(new_user_session_path)
      end
    end
  end

  context 'for admin' do
  	before(:each) do
  		@admin = Factory(:admin)
  		set_session_for(@admin)
		end

    it_should_behave_like 'be_able_to_perform_index#repositories'
    it_should_behave_like 'be_able_to_perform_show#repositories'

    it 'should be able to perform new action' do
      get :new, :platform_id => @platform.id
      response.should render_template(:new)
    end

    it 'should be able to perform create action' do
      post :create, @create_params
      response.should redirect_to(platform_repositories_path(@platform.id))
    end

    it 'should change objects count after create action' do
      lambda { post :create, @create_params }.should change{ Repository.count }.by(1)
    end

    it_should_behave_like 'be_able_to_perform_destroy#repositories'
    it_should_behave_like 'change_repositories_count_after_destroy'
    it_should_behave_like 'be_able_to_perform_add_project#repositories'
    it_should_behave_like 'be_able_to_perform_add_project#repositories_with_project_id_param'
    it_should_behave_like 'add_project_to_repository'
    it_should_behave_like 'be_able_to_perform_remove_project#repositories'
    it_should_behave_like 'remove_project_from_repository'
    it_should_behave_like 'not_be_able_to_destroy_personal_repository'
  end

  context 'for anyone except admin' do
  	before(:each) do
  		@user = Factory(:user)
  		set_session_for(@user)
		end

    it 'should not be able to perform new action' do
      get :new, :platform_id => @platform.id
      response.should redirect_to(forbidden_path)
    end

    it 'should not be able to perform create action' do
      post :create, @create_params
      response.should redirect_to(forbidden_path)
    end

    it 'should not change objects count after create action' do
      lambda { post :create, @create_params }.should change{ Repository.count }.by(0)
    end

    it_should_behave_like 'not_be_able_to_destroy_personal_repository'
  end

  context 'for owner user' do
  	before(:each) do
  		@user = Factory(:user)
  		set_session_for(@user)
  		@repository.update_attribute(:owner, @user)
  		r = @repository.relations.build(:object_type => 'User', :object_id => @user.id, :role => 'admin')
  		r.save!
		end

    it_should_behave_like 'be_able_to_perform_index#repositories'
    it_should_behave_like 'be_able_to_perform_show#repositories'
    it_should_behave_like 'be_able_to_perform_add_project#repositories'
    it_should_behave_like 'be_able_to_perform_add_project#repositories_with_project_id_param'
    it_should_behave_like 'add_project_to_repository'
    it_should_behave_like 'be_able_to_perform_remove_project#repositories'
    it_should_behave_like 'remove_project_from_repository'
    it_should_behave_like 'be_able_to_perform_destroy#repositories'
    it_should_behave_like 'change_repositories_count_after_destroy'
  end

  context 'for reader user' do
  	before(:each) do
  		@user = Factory(:user)
  		set_session_for(@user)
  		r = @repository.relations.build(:object_type => 'User', :object_id => @user.id, :role => 'reader')
  		r.save!
		end

    it_should_behave_like 'be_able_to_perform_index#repositories'
    it_should_behave_like 'be_able_to_perform_show#repositories'

    it 'should not be able to perform add_project action' do
      get :add_project, :id => @repository.id
      response.should redirect_to(forbidden_path)
    end

    it 'should not be able to perform add_project action with project_id param' do
      get :add_project, :id => @repository.id, :project_id => @project.id
      response.should redirect_to(forbidden_path)
    end

    it 'should not be able to perform destroy action' do
      delete :destroy, :id => @repository.id
      response.should redirect_to(forbidden_path)
    end
  end
end
