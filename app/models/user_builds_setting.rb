class UserBuildsSetting < ActiveRecord::Base
  include ExternalNodable

  belongs_to :user

  validates :user, presence: true

  attr_accessible :platforms,
                  :use_extra_tests

end
