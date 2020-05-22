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

class BatchFilesController < ApplicationController

  UPLOAD_NOTICE = "Your upload has been received and is now being processed. This may take some time depending on the size of the file. The status of your uploads can be seen in the table below. Click the 'Refresh Status' button to see an updated status."
  FORCE_SUBMIT_NOTICE = "Your request is now being processed. This may take some time depending on the size of the file. The status of your uploads can be seen in the table below. Click the 'Refresh Status' button to see an updated status."
  PAPERCLIP_SPOOFED_MEDIA_TYPE_MSG = 'has contents that are not what they are reported to be'

  before_action :authenticate_user!

  before_action except:[] do
    redirect_back(fallback_location: root_path, alert: 'There are no clinic allocated to you.') if !current_user.role.super_user? && current_user.clinics.where(capturesystem:current_capturesystem).empty?
  end

  load_and_authorize_resource

  expose(:year_of_registration_range) { ConfigurationItem.year_of_registration_range }
  expose(:group_names_by_survey) { Question.group_names_by_survey }
  #expose(:surveys) { SURVEYS.values }
  #REMOVE_ABOVE

  def new
  end

  def index
    set_tab :batches, :home
    @batch_files = @batch_files.where(clinic: current_capturesystem.clinics).order("created_at DESC").page(params[:page]).per_page(20)
  end

  def force_submit
    raise "Can't force with status #{@batch_file.status}" unless @batch_file.force_submittable?
    @batch_file.status = BatchFile::STATUS_IN_PROGRESS
    @batch_file.save!

    @batch_file.delay.process(:force)
    redirect_to batch_files_path, notice: FORCE_SUBMIT_NOTICE
  end

  def create
    @batch_file.user = current_user
    if @batch_file.save
      @batch_file.delay.process
      redirect_to batch_files_path, notice: UPLOAD_NOTICE
    else
      replace_paperclip_spoof_error_with_invalid_csv_msg
      render :new
    end
  end

  def summary_report
    raise "No summary report for batch file" unless @batch_file.has_summary_report?

    the_batch_file_css = @batch_file.survey.capturesystems.ids
    user_css = current_user.capturesystem_users.where(access_status:CapturesystemUser::STATUS_ACTIVE).pluck(:capturesystem_id)
    return redirect_back(fallback_location: root_path, alert: 'Can not access unidentifieable resource.') if (the_batch_file_css & user_css).empty?

    send_file @batch_file.summary_report_path, :type => 'application/pdf', :disposition => 'attachment', :filename => "summary-report.pdf"
  end

  def detail_report
    raise "No detail report for batch file" unless @batch_file.has_detail_report?

    the_batch_file_css = @batch_file.survey.capturesystems.ids
    user_css = current_user.capturesystem_users.where(access_status:CapturesystemUser::STATUS_ACTIVE).pluck(:capturesystem_id)
    return redirect_back(fallback_location: root_path, alert: 'Can not access unidentifieable resource.') if (the_batch_file_css & user_css).empty?

    send_file @batch_file.detail_report_path, :type => 'text/csv', :disposition => 'attachment', :filename => "detail-report.csv"
  end

  def download_index_summary
    index_summary = CSV.generate(:col_sep => ",") do |csv|
      csv.add_row %w(Treatment\ Data Year\ of\ Treatment Unit\ Name Site\ Number Filename Records Created\ By Date\ Uploaded Status Summary)
      @batch_files.where(clinic: current_capturesystem.clinics).order("created_at DESC").each do |batch_file|
        csv.add_row [batch_file.survey.name, batch_file.year_of_registration, batch_file.clinic.unit_name,
                     batch_file.clinic.site_code, batch_file.file_file_name, batch_file.record_count,
                     batch_file.user.full_name, batch_file.created_at, batch_file.status, batch_file.message]
      end
    end
    send_data index_summary, :type => 'text/csv', :disposition => "attachment", :filename =>'batch_files.csv'
  end

  private

  def create_params
    params.require(:batch_file).permit(:survey_id, :year_of_registration, :file, :clinic_id)
  end

  def replace_paperclip_spoof_error_with_invalid_csv_msg
    if @batch_file.errors.include? :file
      @batch_file.errors[:file].collect! do |error|
        (error == PAPERCLIP_SPOOFED_MEDIA_TYPE_MSG) ? BatchFile::MESSAGE_BAD_FORMAT : error
      end
    end
  end

end
