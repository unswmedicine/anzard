class UserSessionsController < Devise::SessionsController
  skip_before_action :verify_authenticity_token, only: [:create_from]
  skip_before_action :authenticate_user!, only: [:create_from], raise: false
  #prepend_before_action only: [:create_from] do
    #request.env["devise.skip_timeout"] = true
  #end

  def new
    #Always go to the master site for login
    if !current_capturesystem.nil? && !user_signed_in?
      return redirect_to CapturesystemUtils.master_site_base_url
    end
    super
  end

  def create
    if User.find_by(email: params[:user][:email]).nil?
      set_flash_message!(:alert, :invalid, scope: [:devise, :failure])
      return redirect_to root_path
    end
    super
  end

  def destroy
    current_user.invalidate_sessions! if user_signed_in?
    super
  end

  def create_from
    the_user_id,the_authenticatable_salt = get_warden_user_user_key_from_cookie(params[:stored_session])

    the_user = User.find_by_id(the_user_id)
    if the_user.nil?
      set_flash_message!(:alert, :invalid, scope: [:devise, :failure])
      logger.error "Received stored_session with an invalid user_id [#{the_user_id}]"
      return redirect_to root_path
    end
    if !current_capturesystem.nil? && the_user.capturesystem_users.find_by(capturesystem: current_capturesystem, access_status: CapturesystemUser::STATUS_ACTIVE).nil?
      set_flash_message!(:alert, :invalid, scope: [:devise, :failure])
      logger.error "Received stored_session for user [#{the_user.email}] with no permission to capture system at [#{request.host}]"
      return redirect_to root_path
    end

    if the_user.authenticatable_salt == the_authenticatable_salt
      reset_session
      bypass_sign_in(the_user)
      #session.update old_values.except('session_id')
      #set_flash_message!(:notice, :signed_in_with_session_in_cookie)
      logger.debug "Session has been created for the user [#{the_user.email}] at [#{request.host}]"
    else
      set_flash_message!(:alert, :invalid, scope: [:devise, :failure])
      logger.error "Received invalid stored_session for user [#{the_user.email}] at [#{request.host}]"
    end
    return redirect_to root_path
  end

  def goto_system
    if user_signed_in? && !params[:system_url].blank? && !params[:from_url].blank?
      response.headers['Access-Control-Allow-Origin']=params[:from_url]
      response.headers['Access-Control-Request-Method']= %w{GET POST OPTIONS}.join(",")

      @requested_capturesystem = Capturesystem.find_by(base_url: params[:system_url])
      if @requested_capturesystem.nil? && CapturesystemUtils.master_site_base_url != params[:system_url] 
        return redirect_to(root_path, alert: 'Your access request to capture system is invalid')
      else
        @requested_capturesystem_user = CapturesystemUser.find_by(capturesystem: @requested_capturesystem, user: current_user)
        (render :goto_system && return) if @requested_capturesystem_user.nil? 

        case @requested_capturesystem_user.access_status
        when nil, '', CapturesystemUser::STATUS_UNAPPROVED
          return redirect_to(root_path, alert:"Your request to access #{@requested_capturesystem.name} is pending")
        when CapturesystemUser::STATUS_DEACTIVATED
          return redirect_to(root_path, alert:"Your access to #{@requested_capturesystem.name} has been dactivated")
        when CapturesystemUser::STATUS_REJECTED
          return redirect_to(root_path, alert:"Your request to access #{@requested_capturesystem.name} has been rejected")
        else
          render :goto_system && return
        end
      end
    else
      return redirect_to root_path
    end
  end

private

  def get_warden_user_user_key_from_cookie(cookie_str)
      hashed_session, session_signature=cookie_str.split('--')
      if OpenSSL::HMAC.hexdigest(OpenSSL::Digest::SHA1.new, Rails.application.config.secret_key_base, hashed_session) == session_signature 
        unfolded_session=Marshal.load(Base64.strict_decode64(hashed_session))
        #"users.id"
        [unfolded_session["warden.user.user.key"][0][0].to_i, unfolded_session["warden.user.user.key"][1]]
      else
        [-1, 'not_authenticatable']
      end
  end

end