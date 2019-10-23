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

// This is a manifest file that'll be compiled into including all the files listed below.
// Add new JavaScript/Coffee code in separate files in this directory and they'll automatically
// be included in the compiled file accessible from http://example.com/assets/application.js
// It's not advisable to add code directly here, but if you do, it'll appear at the bottom of the
// the compiled file.
//
// To add bootstrap js, see https://github.com/thomas-mcdonald/bootstrap-sass


//= require jquery
//= require jquery_ujs
//= require bootstrap
//= require help_text
//= require section_navigation
//= require show_hide_multi_questions
//= require deselect_option
//= require cancel_delete
//= require populate_site_on_unit_select
//= require new_clinic
//= require populate_treatment_data_on_year_select

$(window).load(function () {
  $('.row div[class^="span"]:last-child').addClass('last-child');
});
