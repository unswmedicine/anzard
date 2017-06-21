module Admin::UsersHelper

  def hospital_filter_options(current_selection)
    hospitals = grouped_options_for_select(Clinic.hospitals_by_state_with_site_name, current_selection)
    others = if current_selection == "None"
               '<option value="">ANY</option><option value="None" selected>None</option>'
             else
               '<option value="">ANY</option><option value="None">None</option>'
             end
    (others + hospitals).html_safe
  end
end
