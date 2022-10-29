class UserDecorator
  attr_reader :user, :view_context
  def initialize(user, view_context)
    @user, @view_context = user, view_context
  end

  def name
    "#{user.first_name} #{user.last_name.first}."
  end

  def staff_badge
    view_context.content_tag(:span, 'Staff', class: 'badge badge-success') if user.admin?
  end

  def mod_badge
    view_context.content_tag(:span, 'Mod', class: 'badge badge-primary') if user.moderator?
  end

  def to_s
    name
  end

end

