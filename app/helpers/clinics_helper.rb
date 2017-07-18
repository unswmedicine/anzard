module ClinicsHelper

  def clinics_unit_filter_options(current_selection)
    clinics = grouped_options_for_select(Clinic.units_by_state_with_unit_code, current_selection)
    ('<option value="">ANY</option>' + clinics).html_safe
  end

  def clinics_unit_options
    units = Clinic.distinct_unit_list
    options = options_for_select(units.map{ |unit| ["(#{unit[:unit_code]}) #{unit[:unit_name]}", unit[:unit_code]] })
    ('<option value="">New Unit</option>' + options).html_safe
  end

end
