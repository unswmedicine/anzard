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

// help_text.js
// Sets up triggers so that the help text for a question shows at the right times
!function($){
  $(document).ready(function(){

    var $field_trigger = $('.field_trigger');
    var $field_info = $('#field_info');
    var $field_title = $('#field_title');

    var show_help = function(qn_name, qn_code, description, guide_for_use) {
        var formatted = $('' +
            '<div>' +
              '<div id="help-code"><h3>Question Code</h3><p class="code-body"></div>' +
              '<div id="help-desc"><h3>Definition</h3><p class="desc-body"></div>' +
              '<div id="help-guide"><h3>Guide For Use</h3><p class="guide-body"></div>' +
            '</div>');
        formatted.find('.desc-body').html(description);
        if (guide_for_use != "") {
          formatted.find('.guide-body').html(guide_for_use);
        } else {
          formatted.find('#help-guide').remove();
        }

        formatted.find('.code-body').text(qn_code);
        $field_info.html(formatted);
        $field_title.text(qn_name);
    };

    $field_trigger.bind('focus click', function(){
      var $this = $(this);
      var guide_for_use = $this.data('guide');
      var qn_name = $this.data('name');
      var qn_code = $this.data('code');
      var description = $this.data('description');

      show_help(qn_name, qn_code, description, guide_for_use);

    });
  });
}(jQuery);
