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

class Ability
  include CanCan::Ability

  # ToDo: add unit tests for abilities
  def initialize(user)

    # aliases for user management actions
    alias_action :reject, to: :update
    alias_action :reject_as_spam, to: :update
    alias_action :deactivate, to: :update
    alias_action :activate, to: :update
    alias_action :edit_role, to: :update
    alias_action :update_role, to: :update
    alias_action :edit_approval, to: :update
    alias_action :approve, to: :update
    alias_action :access_requests, to: :read

    # aliases for responses actions
    alias_action :review_answers, to: :read

    # aliases for batch files actions
    alias_action :summary_report, to: :read
    alias_action :detail_report, to: :read

    alias_action :prepare_download, to: :download

    return unless user.role

    #All users can see all available surveys
    can :read, Survey

    if user.role.name == Role::SUPER_USER
      can :force_submit, BatchFile do |batch_file|
        batch_file.force_submittable?
      end
      can :submit, Response, clinic_id: Clinic.all.ids, submitted_status: Response::STATUS_UNSUBMITTED, validation_status: [Response::COMPLETE_WITH_WARNINGS]
    elsif user.role.name == Role::DATA_PROVIDER || user.role.name == Role::DATA_PROVIDER_SUPERVISOR
      can :submit, Response, clinic_id: user.clinic_ids, submitted_status: Response::STATUS_UNSUBMITTED, validation_status: Response::COMPLETE
    end

    case user.role.name
      when Role::SUPER_USER
        can :read, User
        can :update, User
        can :get_active_sites, User

        can :read, Response
        can :download_index_summary, Response
        can :submission_summary, Response
        can :download_submission_summary, Response
        can :download, Response
        can :get_sites, Response
        can :batch_delete, Response
        can :confirm_batch_delete, Response
        can :perform_batch_delete, Response
        can :read, BatchFile
        can :download_index_summary, BatchFile

        can :manage, ConfigurationItem

        can :read, SurveyConfiguration
        can :edit, SurveyConfiguration
        can :update, SurveyConfiguration

        can :read, Clinic
        can :edit, Clinic
        can :update, Clinic
        can :new, Clinic
        can :create, Clinic
        can :edit_unit, Clinic
        can :update_unit, Clinic
        can :activate, Clinic
        can :deactivate, Clinic

      when Role::DATA_PROVIDER
        can :read, Response, clinic_id: user.clinic_ids, submitted_status: Response::STATUS_UNSUBMITTED
        can :download_index_summary, Response, clinic_id: user.clinic_ids, submitted_status: Response::STATUS_UNSUBMITTED
        can :new, Response
        can :create, Response, clinic_id: user.clinic_ids
        can :update, Response, clinic_id: user.clinic_ids, submitted_status: Response::STATUS_UNSUBMITTED

        can :read, BatchFile, clinic_id: user.clinic_ids
        can :download_index_summary, BatchFile, clinic_id: user.clinic_ids
        can :new, BatchFile
        can :create, BatchFile

      when Role::DATA_PROVIDER_SUPERVISOR
        can :read, Response, clinic_id: user.clinic_ids, submitted_status: Response::STATUS_UNSUBMITTED
        can :download_index_summary, Response, clinic_id: user.clinic_ids, submitted_status: Response::STATUS_UNSUBMITTED
        can :new, Response
        can :create, Response, clinic_id: user.clinic_ids
        can :update, Response, clinic_id: user.clinic_ids, submitted_status: Response::STATUS_UNSUBMITTED
        can :destroy, Response, clinic_id: user.clinic_ids

        can :read, BatchFile, clinic_id: user.clinic_ids
        can :download_index_summary, BatchFile, clinic_id: user.clinic_ids
        can :new, BatchFile
        can :create, BatchFile
      else
        raise "Unknown role #{user.role.name}"
    end

  end
end
