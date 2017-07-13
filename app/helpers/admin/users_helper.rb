module Admin::UsersHelper

  def clinic_unit_filter_options(current_selection)
    clinics = grouped_options_for_select(Clinic.units_by_state_with_unit_code, current_selection)
    filter_options_with_selected(clinics, current_selection)
  end

  def clinic_site_filter_options(current_selection)
    clinics = grouped_options_for_select(Clinic.clinics_by_state_with_clinic_id, current_selection)
    filter_options_with_selected(clinics, current_selection)
  end

  private

  def filter_options_with_selected(clinics, current_selection)
    if current_selection == 'None'
      others = '<option value="">ANY</option><option value="None" selected>None</option>'
    else
      others = '<option value="">ANY</option><option value="None">None</option>'
    end
    (others + clinics).html_safe
  end
end
