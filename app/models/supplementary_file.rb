class SupplementaryFile < ApplicationRecord
  # ToDo: remove supplementary files from the app as it is ANZNN-specific and not relevant to ANZARD

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
        unless row.headers.include?(BatchFile::CYCLE_ID_COLUMN)
          self.message = "The supplementary file you uploaded for '#{multi_name}' did not contain a CYCLE_ID column."
          return false
        end
        cycle_id = row[BatchFile::CYCLE_ID_COLUMN]
        if cycle_id.blank?
          self.message = "The supplementary file you uploaded for '#{multi_name}' is missing one or more cycle IDs. Each record must have a cycle ID."
          return false
        else
          self.supplementary_data[cycle_id] ||= []
          self.supplementary_data[cycle_id] << row
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

    supplementary_data.each_pair do |cycle_id, rows_for_cycle|
      if rows_for_cycle
        answer_hash = {}
        rows_for_cycle.each_with_index do |row, index|
          answers = row.to_hash
          answers.delete('CYCLE_ID')
          answers.each_pair do |key, value|
            answer_hash["#{key}#{index+1}"] = value unless value.blank?
          end
        end
        self.denormalised[cycle_id] = answer_hash
      end
    end

    self.denormalised
  end

end
