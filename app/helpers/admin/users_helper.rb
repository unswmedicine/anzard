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

module Admin::UsersHelper

  def users_clinic_unit_filter_options(current_selection)
    clinics = grouped_options_for_select(Clinic.units_by_state_with_unit_code(current_capturesystem), current_selection)
    filter_options_with_selected(clinics, current_selection)
  end

  def users_clinic_site_filter_options(current_selection)
    clinics = grouped_options_for_select(Clinic.clinics_by_state_with_clinic_id(current_capturesystem), current_selection)
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
