// ANZARD - Australian & New Zealand Assisted Reproduction Database
// Copyright (C) 2017 Intersect Australia Ltd
//
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
//
// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
// GNU General Public License for more details.
//
// You should have received a copy of the GNU General Public License
// along with this program. If not, see <http://www.gnu.org/licenses/>.

$(window).load(function () {
    $('#new_clinic #unit_selection').change(function() {
        var selected_unit_code = this.value;
        var unit_code_input = $('#new_clinic #clinic_unit_code');
        var unit_name_input = $('#new_clinic #clinic_unit_name');
        if (selected_unit_code == '') {
            unit_code_input.prop('readonly', false);
            unit_code_input.val('');
            unit_name_input.prop('readonly', false);
            unit_name_input.val('');
        } else {
            unit_code_input.prop('readonly', true);
            unit_code_input.val(selected_unit_code);
            var selected_option_text = $(this).find('option:selected').text();
            unit_name_input.prop('readonly', true);
            // Set the Unit Name to the option text without the Unit Code in brackets and space before Unit Name
            unit_name_input.val(selected_option_text.substr(3 + selected_unit_code.length));
        }
    });
});