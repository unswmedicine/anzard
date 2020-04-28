module CapturesystemsHelper

  def capturesystems_for_user(the_user)
    the_user.capturesystems.map { |n| [ "#{n.name}", n.base_url ]}
  end
end
