class PagesController < ApplicationController

  skip_before_action :authenticate_user!, only: :home, raise: false

  def home
    if user_signed_in?
      set_tab :responses, :home
      @responses = Response.accessible_by(current_ability).unsubmitted.order("cycle_id")
    end
  end
end
