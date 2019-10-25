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
   function get_treatment_data_based_on_year($year_of_treatment, $treatment_form) {
       $.ajax({
           type: 'GET',
           url: '/responses/treatment_data_for_year',
           dataType: 'json',
           async: true,
           data: { year: $year_of_treatment.val()},
           success: function (data) {
               let options = '';
               if (data.length === 0) {
                   options = '<option value="">No data for selected year</option>';
               } else {
                   if (data.length > 1) {
                       options = '<option value="">Please select</option>';
                   }
                   for (let x = 0; x < data.length; x++) {
                       options += '<option value="' + data[x]['form_id'] + '">' + data[x]['form_name'] + '</option>';
                   }
               }
               $treatment_form.html(options);
           }
       });
   }

   let $new_response_treatment_year = $('#new_response #response_year_of_registration');
   let $new_response_treatment_form = $('#new_response #response_survey_id');

   // Data Entry Form - populate Treatment Data on page load such as when new response creation was invalid
   if ($new_response_treatment_year.length && $new_response_treatment_form) {
       get_treatment_data_based_on_year($new_response_treatment_year,$new_response_treatment_form);
   }

   // Data Entry Form - populate Treatment Data on Year of Treatment selection
   $new_response_treatment_year.change(function() {
       get_treatment_data_based_on_year($new_response_treatment_year, $new_response_treatment_form);
   });

   let $new_batch_file_treatment_year = $('#new_batch_file #batch_file_year_of_registration');
   let $new_batch_file_treatment_form = $('#new_batch_file #batch_file_survey_id');

   // Batch File Upload - populate Treatment Data on page load such as when new batch file creation was invalid
   if ($new_batch_file_treatment_year.length && $new_batch_file_treatment_form) {
       get_treatment_data_based_on_year($new_batch_file_treatment_year, $new_batch_file_treatment_form);
   }

   // Data Entry Form - populate Treatment Data on Year of Treatment selection
   $new_batch_file_treatment_year.change(function() {
       get_treatment_data_based_on_year($new_batch_file_treatment_year, $new_batch_file_treatment_form);
   });
});