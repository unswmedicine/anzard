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

require 'rails_helper'

describe BatchFileCleaner do
  it "deletes old failed batch files" do
    batch_file = create :batch_file, status: BatchFile::STATUS_FAILED, updated_at: 35.days.ago

    lambda do
      subject.delete_old_files
    end.should change(BatchFile, :count).by(-1)
  end

  it "does not delete old 'non failed' files" do
    batch_file = create :batch_file, status: BatchFile::STATUS_SUCCESS, updated_at: 35.days.ago

    lambda do
      subject.delete_old_files
    end.should_not change(BatchFile, :count)
  end

  it "does not delete recent failed files" do
    batch_file = create :batch_file, status: BatchFile::STATUS_FAILED, updated_at: 25.days.ago

    lambda do
      subject.delete_old_files
    end.should_not change(BatchFile, :count)
  end
end

