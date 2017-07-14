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
      can :submit, Response, clinic_id: user.clinic_ids, submitted_status: Response::STATUS_UNSUBMITTED, validation_status: [Response::COMPLETE, Response::COMPLETE_WITH_WARNINGS]
    elsif user.role.name == Role::DATA_PROVIDER
      can :submit, Response, clinic_id: user.clinic_ids, submitted_status: Response::STATUS_UNSUBMITTED, validation_status: Response::COMPLETE
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

        can :read, Clinic

      when Role::DATA_PROVIDER
        can :read, Response, clinic_id: user.clinic_ids, submitted_status: Response::STATUS_UNSUBMITTED
        can :new, Response
        can :create, Response, clinic_id: user.clinic_ids
        can :update, Response, clinic_id: user.clinic_ids, submitted_status: Response::STATUS_UNSUBMITTED

        # ToDo: (ANZARD-16 / ANZARD-38) Update data provider ability so that they can read and create batch files for all of their clinics
        can :read, BatchFile, clinic_id: user.clinic_ids
        can :new, BatchFile
        # ToDo: add batch file restriction so provider can only create a batch file for their clinics.
        # can :create, BatchFile, clinic_id: user.clinic_ids
        can :create, BatchFile
        can :submitted_cycle_ids, Response

      when Role::DATA_PROVIDER_SUPERVISOR
        can :read, Response, clinic_id: user.clinic_ids, submitted_status: Response::STATUS_UNSUBMITTED
        can :new, Response
        can :create, Response, clinic_id: user.clinic_ids
        can :update, Response, clinic_id: user.clinic_ids, submitted_status: Response::STATUS_UNSUBMITTED
        can :destroy, Response, clinic_id: user.clinic_ids

        # ToDo: (ANZARD-16 / ANZARD-38) Update data supervisor ability so that they can read and create batch files for all of their clinics
        can :read, BatchFile, clinic_id: user.clinic_ids
        can :new, BatchFile
        # ToDo: add batch file restriction so supervisor can only create a batch file for their clinics.
        # can :create, BatchFile, clinic_id: user.clinic_ids
        can :create, BatchFile

        can :submitted_cycle_ids, Response
      else
        raise "Unknown role #{user.role.name}"
    end

  end
end
