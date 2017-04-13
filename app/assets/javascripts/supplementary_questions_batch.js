$(function() {
  showHideSupplementary();

  $('#batch_file_survey_id').on('change', function(){
    showHideSupplementary();
  });
});

function showHideSupplementary() {
  $('.supplementary_group').hide();

  // We always want these hidden for ANZARD as they are only used by ANZNN.

  /*var selected_survey_id = $('#batch_file_survey_id').val();
  if(selected_survey_id) {
    var div_id = "#supplementary_" + selected_survey_id;
    $(div_id).show();
  }*/
}