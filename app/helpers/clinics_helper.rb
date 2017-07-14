module ClinicsHelper

  def clinics_unit_filter_options(current_selection)
    clinics = grouped_options_for_select(Clinic.units_by_state_with_unit_code, current_selection)
    ('<option value="">ANY</option>' + clinics).html_safe
  end

end
