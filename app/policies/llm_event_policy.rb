class LlmEventPolicy < ApplicationPolicy
  def show?
    user&.admin?
  end

  class Scope < Scope
    def resolve
      return scope.none unless user&.admin?

      scope.all
    end
  end
end
