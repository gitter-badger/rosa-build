class ActivityFeedsController < ApplicationController
  before_filter :authenticate_user!

  def index
    @activity_feeds = current_user.activity_feeds.order('created_at DESC').limit(10)
  end
end