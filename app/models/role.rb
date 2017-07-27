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

class Role < ApplicationRecord

  SUPER_USER = 'Administrator'
  DATA_PROVIDER = 'Data Provider'
  DATA_PROVIDER_SUPERVISOR = 'Data Provider Supervisor'

  has_many :users

  validates :name, presence: true, uniqueness: {case_sensitive: false}

  scope :by_name, -> {order('name')}
  scope :superuser_roles, -> {where(name: SUPER_USER)}

  def super_user?
    self.name.eql? SUPER_USER
  end

  def self.super_user_role
    SUPER_USER
  end

end
