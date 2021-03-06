class ProductBuildListPolicy < ApplicationPolicy

  def index?
    true
  end

  def show?
    is_admin? || ProductPolicy.new(user, record.product).show?
  end
  alias_method :log?,  :show?
  alias_method :read?, :show?

  def create?
    return false unless record.project && record.product
    is_admin? || ProjectPolicy.new(user, record.project).write? || ProductPolicy.new(user, record.product).update?
  end
  alias_method :cancel?, :create?

  def update?
    is_admin? || ProductPolicy.new(user, record.product).update?
  end

  def destroy?
    is_admin? || ProductPolicy.new(user, record.product).destroy?
  end

end
