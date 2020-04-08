$(window).load(function () {
    function populate_years_on_treatment_select($treatment_select, $year_select) {
        $.ajax({
            type: 'GET',
            url: '/responses/year_for_treatment_data',
            dataType: 'json',
            async: true,
            data: {treatment_form: $treatment_select.val()},
            success: function (data) {
                let options = '';
                if (data.length === 0) {
                    options = '<option value="">No year for selected Treatment Data</option>';
                } else {
                    if (data.length > 1) {
                        options = '<option value="">Please select</option>';
                    }
                    for (let x = 0; x < data.length; x++) {
                        options += '<option value="' + data[x]['year'] + '">' + data[x]['year'] + '</option>';
                    }
                }
                $year_select.html(options);
            }
        });
    }
    let $batch_delete_year = $('#batch_delete_form #year_of_registration');
    let $batch_delete_treatment_data = $('#batch_delete_form #treatment_data');

    // Data Entry Form - populate Treatment Data on page load such as when new response creation was invalid
    // if ($batch_delete_treatment_data.length && $batch_delete_year) {
    //     populate_years_on_treatment_select($batch_delete_treatment_data, $batch_delete_year );
    // }

    // Data Entry Form - populate Treatment Data on Year of Treatment selection
    $batch_delete_treatment_data.change(function() {
        populate_years_on_treatment_select( $batch_delete_treatment_data, $batch_delete_year);
    });
});