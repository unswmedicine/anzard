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

class ResponsesController < ApplicationController
  before_action :authenticate_user!

  before_action except:[] do
    redirect_back(fallback_location: root_path, alert: 'There are no clinic allocated to you.') if !current_user.role.super_user? && current_user.clinics.where(capturesystem:current_capturesystem).empty?
  end

  load_and_authorize_resource

  expose(:year_of_registration_range) { ConfigurationItem.year_of_registration_range(current_capturesystem) }
  expose(:fiscal_year_of_registration_range) { 
    ConfigurationItem.year_of_registration_range(current_capturesystem).map { |year| [ "July #{year-1} to June #{year}", year ] } 
  }
  #expose(:surveys) { SURVEYS.values }
  #REMOVE_ABOVE
  expose(:clinics) { Clinic.where(capturesystem_id: current_capturesystem.id).clinics_by_state_with_clinic_id }
  expose(:existing_years_of_registration) { Response.existing_years_of_registration(current_capturesystem) }

  def index
    @responses = Response.accessible_by(current_ability).unsubmitted.order("cycle_id").where(survey: current_capturesystem.surveys)
  end

  def new

  end

  def show
    return redirect_back(fallback_location: root_path, alert: 'Can not access unidentifieable resource.') unless @response.survey.capturesystems.ids.include?(current_capturesystem&.id)
    #WARNING: this is a performance enhancing hack to get around the fact that reverse associations are not loaded as one would expect - don't change it
    #set_response_value_on_answers(@response)
    #Remove above unverifiable WARNING and reduntant code in the next release
    #@loaded_response = Response.includes(answers: [question: [:cross_question_validations, :question_options]], survey: [sections: [questions: [:answers, :cross_question_validations] ]]).find(@response.id)
    @loaded_response = Response.includes(:answers).find(@response.id)
  end

  def submit
    @response.submit!
    redirect_to responses_path, notice: "Data Entry Form for #{@response.cycle_id} to #{@response.survey.name} was submitted successfully."
  end

  def create
    return redirect_back(fallback_location: root_path, alert: 'Please select a valid clinic.') unless current_user.clinic_ids.include?(@response.clinic_id)

    @response.user = current_user
    @response.submitted_status = Response::STATUS_UNSUBMITTED
    original_cycle_id = params[:response][:cycle_id]
    unless original_cycle_id.blank?
      @response.cycle_id = original_cycle_id + '_' + Clinic.find(params[:response][:clinic_id]).site_code.to_s
    end
    if @response.save
      redirect_to edit_response_path(@response, section: @response.survey.first_section.id), notice: 'Data entry form created'
    else
      @response.cycle_id = original_cycle_id
      render :new
    end
  end

  def edit
    #set_response_value_on_answers(@response)
    #REMOVE_ABOVE reduntant code in the next release

    section_id = params[:section]
    #@loaded_response = Response.includes(answers: [question: [:cross_question_validations]], survey: [sections: [questions: [:cross_question_validations, :question_options]]]).find(@response.id)
    @loaded_response = Response.includes(:answers).find(@response.id)

    @section = section_id.blank? ? @loaded_response.survey.first_section : @loaded_response.survey.section_with_id(section_id)

    @questions = @section.questions
    #@questions = @section.questions.includes(:cross_question_validations, :question_options)
    @flag_mandatory = @loaded_response.section_started? @section
    @question_id_to_answers = @loaded_response.prepare_answers_to_section_with_blanks_created(@section)
    @group_info = calculate_group_info(@section, @questions)
  end

  def update
    answers = params[:answers]
    answers ||= {}
    submitted_answers = answers.map { |id, val| [id.to_i, val] }
    submitted_questions = submitted_answers.map { |q_a| q_a.first }
     #WARNING: this is a performance enhancing hack to get around the fact that reverse associations are not loaded as one would expect - don't change it
    #set_response_value_on_answers(@response)
    #REMOVE_ABOVE in the next release

    #@loaded_response = Response.includes(answers:[:question], survey: [sections: [:questions]]).find(@response.id)
    @loaded_response = Response.includes(:answers).find(@response.id)

    Answer.transaction do
      submitted_answers.each do |q_id, answer_value|
        answer = @loaded_response.get_answer_to(q_id)
        if blank_answer?(answer_value)
          answer.destroy if answer
        else
          answer = @loaded_response.answers.build(question_id: q_id) unless answer
          answer.answer_value = answer_value
          answer.save!
        end
      end

      # destroy answers for questions not in section
      section = @loaded_response.survey.section_with_id(params[:current_section])
      if section
        missing_questions = section.questions.select { |q| !submitted_questions.include?(q.id) && q.question_type == Question::TYPE_CHOICE }
        missing_questions.each do |question|
          answer = @loaded_response.get_answer_to(question.id)
          answer.destroy if answer
        end
      end
    end

    # reload and trigger a save so that status is recomputed afresh - DONT REMOVE THIS
    #@loaded_response.reload
    ActiveRecord::Base.connection.clear_query_cache
    #@loaded_response = Response.includes(answers: [question: [:cross_question_validations, :question_options]], survey: [sections: [questions: [:answers, :cross_question_validations] ]]).find(@response.id)
    @loaded_response = Response.includes(:answers).find(@response.id)
     #WARNING: this is a performance enhancing hack to get around the fact that reverse associations are not loaded as one would expect - don't change it
    #set_response_value_on_answers(@response)
    #Remove above unverifiable WARNING and reduntant code in the next release
    @loaded_response.save!

    redirect_after_update(params)
  end

  def destroy
    @response.destroy
    redirect_to responses_path
  end

  def review_answers
    return redirect_back(fallback_location: root_path, alert: 'Can not access unidentifieable resource.') unless @response.survey.capturesystems.ids.include?(current_capturesystem&.id)
    #WARNING: this is a performance enhancing hack to get around the fact that reverse associations are not loaded as one would expect - don't change it
    #set_response_value_on_answers(@response)
    #Remove above unverifiable WARNING and reduntant code in the next release

    #loaded_response = Response.includes(answers: [question: [:cross_question_validations, :question_options]], survey: [sections: [questions: [:answers, :cross_question_validations] ]]).find(@response.id)
    loaded_response = Response.includes(:answers).find(@response.id)
    @sections_to_answers = loaded_response.sections_to_answers_with_blanks_created
  end

  def submission_summary
    set_tab :submission_summary, :home
  end

  def prepare_download
    set_tab :download, :home
  end

  def download
    set_tab :download, :home
    @survey_id = params[:survey_id]
    @unit_code = params[:unit_code]
    @site_code = params[:site_code]
    @year_of_registration = params[:year_of_registration]

    selected_survey = current_capturesystem.surveys.includes(sections: [questions: :section]).find_by(id: @survey_id)
    if selected_survey.nil?
      @errors = ["Please select a valid treatment data"]
      render :prepare_download
    else
      prepend_columns = ['TREATMENT_DATA', 'YEAR_OF_TREATMENT', "#{current_capturesystem.name}_Unit_Name", 'ART_Unit_Name', 'CYCLE_ID']
      generator = CsvGenerator.new(selected_survey, @unit_code, @site_code, @year_of_registration, prepend_columns)
      if generator.empty?
        @errors = ["No data was found for your search criteria"]
        render :prepare_download
      else
        send_data generator.csv, :type => 'text/csv', :disposition => "attachment", :filename => generator.csv_filename
      end
    end
  end

  def get_sites
    render json: Clinic.where(capturesystem_id: current_capturesystem.id, unit_code: params['unit_code'])
  end

  def batch_delete
    set_tab :delete_responses, :admin_navigation
    @sorted_clinics = current_capturesystem.clinics.order(:site_code)
  end

  def confirm_batch_delete
    @year = params[:year_of_registration] || ""
    @treatment_data_id = params[:treatment_data] || ""
    @clinic_id = params[:clinic_id] || ""

    @errors = validate_batch_delete_form(@year, @treatment_data_id)
    if @errors.empty?
      @treatment_data = current_capturesystem.surveys.find(@treatment_data_id.to_i)
      @clinic_site_code_name = ""
      unless @clinic_id.blank?
        @clinic_site_code_name = Clinic.find(@clinic_id).site_name_with_code
      end
      @count = Response.count_per_survey_and_year_of_registration_and_clinic(@treatment_data_id, @year, @clinic_id)
    else
      batch_delete
      render :batch_delete
    end
  end

  def perform_batch_delete
    @year = params[:year_of_registration] || ""
    @treatment_data_id = params[:treatment_data] || ""
    @clinic_id = params[:clinic_id] || ""

    @errors = validate_batch_delete_form(@year, @treatment_data_id)
    if @errors.empty?
      Response.delete_by_survey_and_year_of_registration_and_clinic(@treatment_data_id, @year, @clinic_id)
      redirect_to batch_delete_responses_path, :notice => 'The records were deleted'
    else
      redirect_to batch_delete_responses_path
    end
  end

  def download_index_summary
    index_summary = CSV.generate(:col_sep => ",") do |csv|
      # csv.add_row %w(Cycle\ ID Treatment\ Data Year\ of\ Treatment ANZARD\ Unit ART\ Unit Created\ By Status Date\ Started)
      #csv.add_row %w(Cycle\ ID Treatment\ Data Year\ of\ Treatment ANZARD\ Unit ART\ Unit Created\ By Status Date\ Started)
      csv.add_row ['Cycle ID', 'Treatment Data', 'Year of Treatment', "#{current_capturesystem.name} Unit", 'ART Unit', 'Created By', 'Status', 'Date Started']
      Response.accessible_by(current_ability).unsubmitted.order("cycle_id").where(survey: current_capturesystem.surveys).each do |response|
        csv.add_row [response.cycle_id, response.survey.name, response.year_of_registration,
                     response.clinic.unit_name,
                      response.clinic.unit_code,
                     response.user.full_name,
                     response.validation_status, response.created_at]
      end
    end
    send_data index_summary, :type => 'text/csv', :disposition => "attachment", :filename =>'responses.csv'
  end

  def download_submission_summary
    submission_summary = CSV.generate(:col_sep => ",") do |csv|
      #csv.add_row %w(Treatment\ Data Year\ of\ Treatment ANZARD\ Unit ART\ Unit Status Records)
      csv.add_row ['Treatment Data', 'Year of Treatment', "#{current_capturesystem.name} Unit", 'ART Unit', 'Status', 'Records']
      submission_summary_data.each do |summary|
        #csv.add_row [summary[:survey_name], summary[:year], summary[:unit_name], summary[:site_code], summary[:status],
        #             summary[:num_records],]
        #no use case is identified for above extra comma from discussion with darsha
        csv.add_row [summary[:survey_name], summary[:year], summary[:unit_name], summary[:site_code], summary[:status],
                     summary[:num_records]]
      end
    end
    send_data submission_summary, :type => 'text/csv', :disposition => "attachment", :filename =>'submission_summary.csv'
  end

  def submission_summary_data
    submissions = []
    current_capturesystem.surveys.each do |survey|
      stats = StatsReport.new(survey)
      unless stats.empty?
        stats.years.each do |year|
          #Merged from ANZARD3.0 changes, confirm the purpose of extra comma a the end
          Clinic.where(capturesystem_id: current_capturesystem.id).order(:unit_code, :site_code).each do |clinic|
            [
                {name: Response::STATUS_SUBMITTED, str: Response::STATUS_SUBMITTED},
                {name: Response::STATUS_UNSUBMITTED, str: 'In Progress'}
            ].each do |status|
              #num_records = stats.response_count(year, status[:name], clinic.id,)
              #no use case is identified for above extra comma from discussion with darsha
              num_records = stats.response_count(year, status[:name], clinic.id)
              unless num_records == 'none'
                #submissions.push({survey_name: survey.name, year: year, unit_name: clinic.unit_name,
                                  #site_code: clinic.site_code, status: status[:str], num_records: num_records,

                                 #})
                #no use case is identified for above extra comma from discussion with darsha
                submissions.push({survey_name: survey.name, year: year, unit_name: clinic.unit_name,
                                  site_code: clinic.site_code, status: status[:str], num_records: num_records
                                 })
              end
            end
          end
        end
      end
    end
    # submissions.sort_by { |h| h[:survey_name] }.reverse!.sort_by{|e| -e[:year]}
    submissions.sort_by { |h| h[:survey_name] }.reverse!

  end
  helper_method :submission_summary_data

  def treatment_data_for_year
    #VARTA_YEAER
    survey_configs = SurveyConfiguration.where('start_year_of_treatment <= ? and end_year_of_treatment >= ?', params['year'], params['year']).where(survey: current_capturesystem.surveys)
    surveys = []
    survey_configs.each do |survey_config|
      surveys << { 'form_id': survey_config.survey.id, 'form_name': survey_config.survey.name }
    end
    render json: surveys
  end

  def year_for_treatment_data
    survey_config = SurveyConfiguration.find_by survey_id: params['treatment_form']
    years = []
    if survey_config
      for i in survey_config.start_year_of_treatment..survey_config.end_year_of_treatment do
        years << { 'year': i}
      end
    end
    render json: years
  end

  private

  #deprecated not_used
  def organised_cycle_ids(user)
    clinics = user.clinics
    responses = Response.includes(:survey).where(submitted_status: Response::STATUS_SUBMITTED, clinic_id: clinics)
    responses_by_survey = responses.group_by {|response| response.survey }
    responses_by_survey_and_year = responses_by_survey.map do |survey, responses|
      responses_by_year = responses.group_by{|response| response.year_of_registration }
      ordered_stuff = responses_by_year.map do |year, responses|
        [year, responses.map(&:cycle_id).sort]
      end.sort_by {|year, _| -year}

      [survey.name, ordered_stuff]
    end

    responses_by_survey_and_year.sort_by {|survey, _| survey}
  end

  def validate_batch_delete_form(year, survey_id)
    errors = []
    errors << "Please select a valid survey" if current_capturesystem.surveys.find_by(id: survey_id).nil?
    errors << "Please select a year of registration" if year.blank?
    errors << "Please select a treatment data" if survey_id.blank?
    errors
  end

  def blank_answer?(value)
    value.is_a?(Hash) ? !hash_values_present?(value) : value.blank?
  end

  def hash_values_present?(hash)
    hash.values.any? &:present?
  end

  def redirect_after_update(params)
    clicked = params[:commit]

    go_to_section = params[:go_to_section]

    if clicked =~ /^Save and return to summary page/
      go_to_section = 'summary'
    elsif clicked =~ /^Save and go to next section/
      go_to_section = @loaded_response.survey.section_id_after(go_to_section.to_i)
    end

    if go_to_section == "summary"
      redirect_to @response, notice: 'Your answers have been saved'
    else
      redirect_to edit_response_path(@response, section: go_to_section), notice: 'Your answers have been saved'
    end
  end

  def calculate_group_info(section, questions_in_section)
    group_names = questions_in_section.collect(&:multi_name).uniq.compact
    result = {}
    group_names.each do |g|
      questions_for_group = questions_in_section.select { |q| q.multi_name == g }
      result[g] = GroupedQuestionHandler.new(g, questions_for_group, @question_id_to_answers)
    end
    result
  end

  #deprecated method to be removed in the next release
  def set_response_value_on_answers(response)
    #WARNING: this is a performance enhancing hack to get around the fact that reverse associations are not loaded as one would expect - don't change it
    response.answers.each { |a| a.response = response }
  end

  def create_params
    params.require(:response).permit(:year_of_registration, :survey_id, :cycle_id, :clinic_id)
  end

end
