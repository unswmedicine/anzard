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

// ie6.js
$(function() {
	if ($.browser.msie && parseInt($.browser.version, 10) === 6) {
		$('.row div[class^="span"]:last-child').addClass('last-child');
        $('[class*="span"]').addClass('margin-left-20');
        $(':button[class="btn"], :reset[class="btn"], :submit[class="btn"], input[type="button"]').addClass('button-reset');
        $(':checkbox').addClass('input-checkbox');
        $('.pagination li:first-child a').addClass('pagination-first-child');

        $('.btn-ie6').each(
            function() {
                $(this).click(function() {
                    msg = "You are about to delete this form in progress for CYCLE_ID " + $(this).attr('id')
                        + ". This action cannot be undone. Are you sure you want to delete this form?" 
                    return window.confirm(msg);
                });
            }
        );
        
	}
}); 