$(window).load(function () {
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
});