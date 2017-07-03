$(window).load(function () {
    // Populates Site on Unit select function used when preparing the download of completed responses by an admin
    $('#clinic_id').change(function() {
        $.ajax({
            type: 'GET',
            url: 'get_sites',
            dataType: 'json',
            async: true,
            data: {unit_id: $("#clinic_id option:selected").val()},
            success: function (data) {
                var options = '<option value="">ALL</option>';
                for (var x = 0; x < data.length; x++) {
                    if(data.length > 1) { //If only 1 site is returned then ALL is the default that is used
                        options += '<option value="' + data[x]['site'] + '">' + data[x]['site_name'] + ' (' + data[x]['site'] + ')' + '</option>';
                    }
                }
                $('#site_id').html(options);
            }
        });
    });

    // Populates Site on Unit select function used when editing a user's approval by an admin
    $('#clinic_unit').change(function() {
        $.ajax({
            type: 'GET',
            url: 'get_sites',
            dataType: 'json',
            async: true,
            data: {unit_code: $("#clinic_unit option:selected").val()},
            success: function (data) {
                var options = '<input type="hidden" name="user[clinics][]" value="">';
                for (var x = 0; x < data.length; x++) {
                    options += '<div class="clinic_site">';
                    options += '   <label class="check_box_label" for="user_clinics_' + data[x]['id'] + '">';
                    options += '      <input type="checkbox" value="' + data[x]['id'] + '" name="user[clinics][]" id="user_clinics_' + data[x]['id'] + '">';
                    options += '      (' + data[x]['unit_code'] + '-' + data[x]['site_code'] + ') ' + data[x]['site_name'];
                    options += '   </label>';
                    options += '</div>';
                }
                $('#user_clinics').html(options);
            }
        });
    });
});