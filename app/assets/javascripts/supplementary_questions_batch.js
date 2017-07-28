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

$(function() {
  showHideSupplementary();

  $('#batch_file_survey_id').on('change', function(){
    showHideSupplementary();
  });
});

function showHideSupplementary() {
  $('.supplementary_group').hide();

  // ToDo: remove lingering ANZNN supplementary file code
  // We always want these hidden for ANZARD as they are only used by ANZNN.

  /*var selected_survey_id = $('#batch_file_survey_id').val();
  if(selected_survey_id) {
    var div_id = "#supplementary_" + selected_survey_id;
    $(div_id).show();
  }*/
}