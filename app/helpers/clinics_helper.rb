# ANZARD - Australian & New Zealand Assisted Reproduction Database
# Copyright (C) 2017 Intersect Australia Ltd
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program. If not, see <http://www.gnu.org/licenses/>.

module ClinicsHelper

  def clinics_unit_filter_options(current_selection)
    clinics = grouped_options_for_select(Clinic.units_by_state_with_unit_code(current_capturesystem), current_selection)
    ('<option value="">ANY</option>' + clinics).html_safe
  end

  def clinics_unit_options(capturesystem)
    units = Clinic.distinct_unit_list(capturesystem)
    options = options_for_select(units.map{ |unit| ["(#{unit[:unit_code]}) #{unit[:unit_name]}", unit[:unit_code]] })
    options.html_safe
  end

  def clinics_unit_options_with_new(capturesystem)
    ('<option value="">New Unit</option>' + clinics_unit_options(capturesystem)).html_safe
  end
end
