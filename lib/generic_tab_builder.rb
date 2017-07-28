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

class GenericTabBuilder < TabsOnRails::Tabs::Builder
  def tab_for(tab, name, options, item_options = {})
    item_options[:class] = 'active' if current_tab?(tab)
    @context.content_tag(:ul, options)
      @context.content_tag(:li, item_options) do
        @context.link_to(name, options)
      end
  end
end
