class TokenPolicy < ApplicationPolicy

  def show?
    # local_admin?(record.subject)
    is_admin? || owner?(record.subject) || local_admin?(record.subject)
  end
  alias_method :create?,   :show?
  alias_method :read?,     :show?
  alias_method :withdraw?, :show?

end
