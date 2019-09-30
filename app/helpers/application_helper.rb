# ANZARD - Australian & New Zealand Assisted Reproduction Database
# Copyright (C) 2017 Intersect Australia Ltd
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program. If not, see <http://www.gnu.org/licenses/>.

module ApplicationHelper

  # set the page title to be used as browser title and h1 at the top of the page
  def title(page_title, span12=false, centered=false)
    content_for(:title) { page_title }
    content_for(:heading) { page_title }
    @heading_span12=span12
    @heading_centered=centered
  end

  # shorthand for the required asterisk
  def required
    "<span class='required' title='Required'>* Required</span>".html_safe
  end

  # convenience method to render a field on a view screen - saves repeating the div/span etc each time
  def render_field(label, value)
    render_field_content(label, (h value))
  end

  # as above but only render if the value is not empty
  def render_field_if_not_empty(label, value)
    render_field_content(label, (h value)) if value != nil && !value.empty?
  end

  # as above but takes a block for the field value
  def render_field_with_block(label, &block)
    content = with_output_buffer(&block)
    render_field_content(label, content)
  end

  # generate a sorting link for a table of values
  def sortable(column, title = nil)
    title ||= column.humanize
    direction = (column == sort_column && sort_direction == "asc") ? "desc" : "asc"
    css_class = (column == sort_column) ? "sort_link current #{sort_direction}" : "sort_link"
    link_to title, params.permit!.merge(sort: column, direction: direction), {class: css_class}
  end
  private

  def render_field_content(label, content)
    div_id = label.tr(" ,", "_").downcase
    html = "<div class='detail-item inlineblock' id='display_#{div_id}'>"
    html << '<strong>'
    html << (h label)
    html << ": "
    html << '</strong>'
    html << content
    html << '</div>'
    html.html_safe
  end


end
