class Comment < ActiveRecord::Base
  belongs_to :commentable, :polymorphic => true
  belongs_to :user
  attr_accessor :project

  validates :body, :user_id, :commentable_id, :commentable_type, :presence => true

  # FIXME
  after_create :subscribe_on_reply, :unless => "commentable_type == 'Grit::Commit'"
  after_create :deliver_new_comment_notification, :unless => "commentable_type == 'Grit::Commit'"

  protected

  def deliver_new_comment_notification
    subscribes = self.commentable.subscribes
    subscribes.each do |subscribe|
      if self.user_id != subscribe.user_id && User.find(subscribe.user).notifier.new_comment_reply && User.find(subscribe.user).notifier.can_notify
        if self.commentable.comments.exists?(:user_id => subscribe.user.id)
          UserMailer.delay.new_comment_reply_notification(self, subscribe.user)
        else
          UserMailer.delay.new_comment_notification(self, subscribe.user)
        end
      end
    end
  end

  def subscribe_on_reply
    self.commentable.subscribes.create(:user_id => self.user_id) if !self.commentable.subscribes.exists?(:user_id => self.user_id)
  end
end