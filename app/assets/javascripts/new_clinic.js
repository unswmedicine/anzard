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