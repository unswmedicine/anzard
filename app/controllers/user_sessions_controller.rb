class UserSessionsController < Devise::SessionsController
  skip_before_action :verify_authenticity_token, only: [:create_from]
  prepend_before_action only: [:create_from] do
    request.env["devise.skip_timeout"] = true
  end

  def create
    if current_capturesystem.users.find_by(email: params[:user][:email]).nil?
      set_flash_message!(:alert, :invalid, scope: [:devise, :failure])
      return redirect_to root_path
    end
    super
  end

  def destroy
    current_user.invalidate_sessions! if user_signed_in?
    super
  end

  #todo system accessability check
  def create_from
    the_user_id,the_authenticatable_salt=get_warden_user_user_key_from_cookie(params[:stored_session])

    if current_capturesystem.users.find_by(id: the_user_id).nil?
      set_flash_message!(:alert, :invalid, scope: [:devise, :failure])
      return redirect_to root_path
    end

    the_user=User.find_by_id(the_user_id)
    if the_user.nil?
      set_flash_message!(:alert, :invalid, scope: [:devise, :failure])
      return redirect_to root_path
    end

    if user_signed_in? 
      logger.debug "Request is received with a pre-existing session"
      if the_user_id == current_user[:id]
        logger.debug "Request appears to be from the same user"
      else
        logger.debug "Request received with a different pre-existing user"
        current_user.invalidate_sessions!
        logger.debug "Sign out the pre-existing user [#{current_user.email}]"
        sign_out(current_user)
      end

      if the_user.authenticatable_salt == the_authenticatable_salt
        bypass_sign_in(the_user)
        set_flash_message!(:notice, :signed_in_with_session_in_cookie)
        logger.debug "Session has been created for the user [#{the_user.email}]"
      else
        set_flash_message!(:alert, :invalid, scope: [:devise, :failure])
        logger.error "Received invalid stored_session"
      end
    else
      logger.debug "There is no pre-existing session stored in the current cookie"
      if the_user.authenticatable_salt == the_authenticatable_salt
        bypass_sign_in(the_user)
        set_flash_message!(:notice, :signed_in_with_session_in_cookie)
        logger.debug "Session has been created for the user [#{the_user.email}]"
      else
        set_flash_message!(:alert, :invalid, scope: [:devise, :failure])
        logger.error "Received invalid stored_session"
      end
    end

    return redirect_to root_path
  end

  def goto_system
    if user_signed_in? && !params[:system_url].blank? && !params[:from_url].blank?
      response.headers['Access-Control-Allow-Origin']=params[:from_url]
      response.headers['Access-Control-Request-Method']= %w{GET POST OPTIONS}.join(",")

      render :goto_system && return
    else
      return redirect_to root_path
    end
  end

private

  def get_warden_user_user_key_from_cookie(cookie_str)
      hashed_session, session_signature=cookie_str.split('--')
      if OpenSSL::HMAC.hexdigest(OpenSSL::Digest::SHA1.new, Rails.application.config.secret_token, hashed_session) == session_signature 
        unfolded_session=Marshal.load(Base64.strict_decode64(hashed_session))
        #"users.id"
        [unfolded_session["warden.user.user.key"][0][0].to_i, unfolded_session["warden.user.user.key"][1]]
      else
        [-1, 'not_authenticatable']
      end
  end

end