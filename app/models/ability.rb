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

    if user.role.name == Role::DATA_PROVIDER_SUPERVISOR
      can :force_submit, BatchFile do |batch_file|
        batch_file.force_submittable?
      end
      # Todo: (ANZARD-16 / ANZARD-38) update ability so user (supervisor role) can submit response for all of their clinics
      can :submit, Response, clinic_id: user.clinic_id, submitted_status: Response::STATUS_UNSUBMITTED, validation_status: [Response::COMPLETE, Response::COMPLETE_WITH_WARNINGS]
    elsif user.role.name == Role::DATA_PROVIDER
      # Todo: (ANZARD-16 / ANZARD-38) update ability so user (provider role) can submit response to all of their clinics
      can :submit, Response, clinic_id: user.clinic_id, submitted_status: Response::STATUS_UNSUBMITTED, validation_status: Response::COMPLETE
    end

    case user.role.name
      when Role::SUPER_USER
        can :read, User
        can :update, User
        can :get_sites, User

        can :read, Response
        can :stats, Response
        can :download, Response
        can :get_sites, Response
        can :batch_delete, Response
        can :confirm_batch_delete, Response
        can :perform_batch_delete, Response
        can :read, BatchFile

        can :manage, ConfigurationItem

      when Role::DATA_PROVIDER
        # ToDo: (ANZARD-16 / ANZARD-38) Update data provider ability so that they can read, create and update responses for all of their clinics
        can :read, Response, clinic_id: user.clinic_id, submitted_status: Response::STATUS_UNSUBMITTED
        can :create, Response, clinic_id: user.clinic_id
        can :update, Response, clinic_id: user.clinic_id, submitted_status: Response::STATUS_UNSUBMITTED

        # ToDo: (ANZARD-16 / ANZARD-38) Update data provider ability so that they can read and create batch files for all of their clinics
        can :read, BatchFile, clinic_id: user.clinic_id
        can :create, BatchFile, clinic_id: user.clinic_id
        can :submitted_cycle_ids, Response

      when Role::DATA_PROVIDER_SUPERVISOR
        # ToDo: (ANZARD-16 / ANZARD-38) Update data supervisor ability so that they can read, create, update and destroy responses for all of their clinics
        can :read, Response, clinic_id: user.clinic_id, submitted_status: Response::STATUS_UNSUBMITTED
        can :create, Response, clinic_id: user.clinic_id
        can :update, Response, clinic_id: user.clinic_id, submitted_status: Response::STATUS_UNSUBMITTED
        can :destroy, Response, clinic_id: user.clinic_id

        # ToDo: (ANZARD-16 / ANZARD-38) Update data supervisor ability so that they can read and create batch files for all of their clinics
        can :read, BatchFile, clinic_id: user.clinic_id
        can :create, BatchFile, clinic_id: user.clinic_id

        can :submitted_cycle_ids, Response
      else
        raise "Unknown role #{user.role.name}"
    end

  end
end
