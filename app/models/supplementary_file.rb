# ANZNN - Australian & New Zealand Neonatal Network
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

class SupplementaryFile < ApplicationRecord
  belongs_to :batch_file
  has_attached_file :file, :styles => {}, :path => :make_file_path
  validates_presence_of :multi_name
  validates_attachment_presence :file
  do_not_validate_attachment_file_type :file

  attr_accessor :message
  attr_accessor :supplementary_data
  attr_accessor :denormalised

  def make_file_path
    # this is a method so that APP_CONFIG has been loaded by the time is executes
    "#{APP_CONFIG['batch_files_root']}/supplementary_:id.:extension"
  end

  def pre_process
    self.supplementary_data = {}

    begin

      CSV.foreach(file.path, {headers: true}) do |row|
        unless row.headers.include?(BatchFile::BABY_CODE_COLUMN)
          self.message = "The supplementary file you uploaded for '#{multi_name}' did not contain a BabyCODE column."
          return false
        end
        baby_code = row[BatchFile::BABY_CODE_COLUMN]
        if baby_code.blank?
          self.message = "The supplementary file you uploaded for '#{multi_name}' is missing one or more baby codes. Each record must have a baby code."
          return false
        else
          self.supplementary_data[baby_code] ||= []
          self.supplementary_data[baby_code] << row
        end
      end

      if self.supplementary_data.empty?
        self.message = "The supplementary file you uploaded for '#{multi_name}' did not contain any data."
        return false
      end
      true

    rescue ArgumentError
      logger.info("Argument error while reading supplementary file #{file.path}")
      # Note: Catching ArgumentError seems a bit odd, but CSV throws it when the file is not UTF-8 which happens if you upload an xls file
      self.message = "The supplementary file you uploaded for '#{multi_name}' was not a valid CSV file."
      false
    rescue CSV::MalformedCSVError
      logger.info("Malformed CSV error while reading supplementary file #{file.path}")
      self.message = "The supplementary file you uploaded for '#{multi_name}' was not a valid CSV file."
      false
    rescue
      logger.error("Unexpected processing error while reading / processing supplementary file #{file.path}: Exception: #{$!.class}, Message: #{$!.message}")
      logger.error $!.backtrace
      self.message = BatchFile::MESSAGE_UNEXPECTED_ERROR
      raise
    end
  end

  def as_denormalised_hash
    raise 'Must call pre_process before requesting denormalised hash' unless self.supplementary_data
    return self.denormalised if self.denormalised
    self.denormalised = {}

    supplementary_data.each_pair do |baby_code, rows_for_baby|
      if rows_for_baby
        answer_hash = {}
        rows_for_baby.each_with_index do |row, index|
          answers = row.to_hash
          answers.delete('BabyCODE')
          answers.each_pair do |key, value|
            answer_hash["#{key}#{index+1}"] = value unless value.blank?
          end
        end
        self.denormalised[baby_code] = answer_hash
      end
    end

    self.denormalised
  end

end
