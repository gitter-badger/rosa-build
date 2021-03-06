class GroupPolicy < ApplicationPolicy

  def index?
    !user.guest?
  end
  alias_method :create?,      :index?
  alias_method :remove_user?, :index?

  def show?
    true
  end

  def reader?
    !user.guest? && ( is_admin? || local_reader? )
  end

  def write?
    !user.guest? && ( is_admin? || owner? || local_writer? )
  end

  def update?
    !user.guest? && ( is_admin? || owner? || local_admin? )
  end
  alias_method :add_member?,      :update?
  alias_method :manage_members?,  :update?
  alias_method :members?,         :update?
  alias_method :remove_member?,   :update?
  alias_method :remove_members?,  :update?
  alias_method :update_member?,   :update?

  def destroy?
    !user.guest? && ( is_admin? || owner? )
  end

  class Scope < Scope
    def show
      scope
    end
  end

end
