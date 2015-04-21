require 'spec_helper'

shared_examples_for 'can subscribe' do
  it 'should be able to perform create action' do
    post :create, @create_params
    expect(response).to redirect_to(project_issue_path(@project, @issue))
  end

  it 'should create subscribe object into db' do
    expect { post :create, @create_params }.to change(Subscribe, :count).by(1)
  end
end

shared_examples_for 'can not subscribe' do
  it 'should not be able to perform create action' do
    post :create, @create_params
    expect(response).to redirect_to(forbidden_path)
  end

  it 'should not create subscribe object into db' do
    expect { post :create, @create_params }.to_not change(Subscribe, :count)
  end
end

shared_examples_for 'can unsubscribe' do
  it 'should be able to perform destroy action' do
    delete :destroy, @destroy_params

    expect(response).to redirect_to([@project, @issue])
  end

  it 'should reduce subscribes count' do
    expect { delete :destroy, @destroy_params }.to change(Subscribe, :count).by(-1)
  end
end

shared_examples_for 'can not unsubscribe' do
  it 'should not be able to perform destroy action' do
    delete :destroy, @destroy_params

    expect(response).to redirect_to(forbidden_path)
  end

  it 'should not reduce subscribes count' do
    expect { delete :destroy, @destroy_params }.to_not change(Subscribe, :count)
  end
end

describe Projects::SubscribesController, type: :controller do
  before(:each) do
    stub_symlink_methods

    @project = FactoryGirl.create(:project)
    @issue = FactoryGirl.create(:issue, project_id: @project.id)

    @create_params =  { issue_id: @issue.serial_id, name_with_owner: @project.name_with_owner }
    @destroy_params = { issue_id: @issue.serial_id, name_with_owner: @project.name_with_owner }

    allow_any_instance_of(Project).to receive(:versions).and_return(%w(v1.0 v2.0))

    @request.env['HTTP_REFERER'] = project_issue_path(@project, @issue)
  end

  context 'for global admin user' do
    before(:each) do
      @user = FactoryGirl.create(:admin)
      set_session_for(@user)
      create_relation(@project, @user, 'admin')
    end

    context 'subscribed' do
      before(:each) do
        ss = @issue.subscribes.build
        ss.user = @user
        ss.save!
      end

      it_should_behave_like 'can unsubscribe'
      it_should_behave_like 'can not subscribe'
    end

    context 'not subscribed' do
      it_should_behave_like 'can subscribe'
    end
  end

  context 'for simple user' do
    before(:each) do
      @user = FactoryGirl.create(:user)
      set_session_for(@user)
      @destroy_params = @destroy_params.merge({id: @user.id})
    end

    context 'subscribed' do
      before(:each) do
        ss = @issue.subscribes.build
        ss.user = @user
        ss.save!
      end

      it_should_behave_like 'can unsubscribe'
      it_should_behave_like 'can not subscribe'
    end

    context 'not subscribed' do
      it_should_behave_like 'can subscribe'
    end
  end
end
