class BuildList < ActiveRecord::Base
  belongs_to :project
  belongs_to :arch
  has_many :items, :class_name => "BuildList::Item", :dependent => :destroy

  validates :project_id, :presence => true
  validates :branch_name, :presence => true

  WAITING_FOR_RESPONSE = 4000
  BUILD_PENDING = 2000
  BUILD_STARTED = 3000

  STATUSES = [WAITING_FOR_RESPONSE,
              BuildServer::SUCCESS,
              BUILD_PENDING,
              BUILD_STARTED,
              BuildServer::BUILD_ERROR,
              BuildServer::PLATFORM_NOT_FOUND,
              BuildServer::PLATFORM_PENDING,
              BuildServer::PROJECT_NOT_FOUND,
              BuildServer::BRANCH_NOT_FOUND]

  HUMAN_STATUSES = { BuildServer::BUILD_ERROR => :build_error,
                     BUILD_PENDING => :build_pending,
                     BUILD_STARTED => :build_started,
                     BuildServer::SUCCESS => :success,
                     WAITING_FOR_RESPONSE => :waiting_for_response,
                     BuildServer::PLATFORM_NOT_FOUND => :platform_not_found,
                     BuildServer::PLATFORM_PENDING => :platform_pending,
                     BuildServer::PROJECT_NOT_FOUND => :project_not_found,
                     BuildServer::BRANCH_NOT_FOUND => :branch_not_found
                    }

  scope :recent, order("created_at DESC")
  scope :current, lambda {
    outdatable_statuses = [BuildServer::SUCCESS, BuildServer::ERROR, BuildServer::PLATFORM_NOT_FOUND, BuildServer::PLATFORM_PENDING, BuildServer::PROJECT_NOT_FOUND, BuildServer::BRANCH_NOT_FOUND]
    where(["status in (?) OR (status in (?) AND notified_at >= ?)", [WAITING_FOR_RESPONSE, BUILD_PENDING, BUILD_STARTED], outdatable_statuses, Time.now - 2.days])
  }
  scope :for_status, lambda {|status| where(:status => status) }
  scope :scoped_to_arch, lambda {|arch| where(:arch_id => arch) }
  scope :scoped_to_branch, lambda {|branch| where(:branch_name => branch) }
  scope :scoped_to_is_circle, lambda {|is_circle| where(:is_circle => is_circle) }
  scope :for_creation_date_period, lambda{|start_date, end_date|
    if start_date && end_date
      where(["created_at BETWEEN ? AND ?", start_date, end_date])
    elsif start_date && !end_date
      where(["created_at >= ?", start_date])
    elsif !start_date && end_date
      where(["created_at <= ?", end_date])
    end
  }
  scope :for_notified_date_period, lambda{|start_date, end_date|
    if start_date && end_date
      where(["notified_at BETWEEN ? AND ?", start_date, end_date])
    elsif start_date && !end_date
      where(["notified_at >= ?", start_date])
    elsif !start_date && end_date
      where(["notified_at <= ?", end_date])
    end
  }

  serialize :additional_repos
  
  before_create :set_default_status
  after_create :place_build

  def self.human_status(status)
    I18n.t("layout.build_lists.statuses.#{HUMAN_STATUSES[status]}")
  end

  def human_status
    self.class.human_status(status)
  end

  def set_items(items_hash)
    self.items = []

    items_hash.each do |level, items|
      items.each do |item|
        self.items << self.items.build(:name => item, :level => level.to_i)
      end
    end
  end

  private
    def set_default_status
      self.status = WAITING_FOR_RESPONSE unless self.status.present?
    end

    def place_build
      self.status = BuildServer.add_build_list project.name, branch_name, project.platform.name, arch.name
      self.status = BUILD_PENDING if self.status == 0
      save
    end
    handle_asynchronously :place_build

end