class UsersController < ApplicationController
  def index
    @user_decorators = User.all.map{ |user| UserDecorator.new(user, view_context) }
  end

end
