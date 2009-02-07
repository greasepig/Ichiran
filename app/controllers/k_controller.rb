class KController < ApplicationController
  verify :session => :user,
         :add_flash => {:message => I18n.t(:unauthorized_action)},
         :redirect_to => {:action => :l},
         :except => [:l, :authenticate]
  def l
    if check_cookie
      session[:user] = DEFAULT_USER
      redirect_to :action => :e
    end
  end

  def authenticate
    if authorized(params[:user], params[:password])
      set_login_cookie
      session[:user] = params[:user]
      redirect_to :action => :e
    else
      flash[:notice] = t :bad_login
      render :action => :l
    end
  end

  def e
    if params[:entry]
      Entry.create(params[:entry]) if params[:entry]
      redirect_to :action => :e
    else
      @entries = Entry.find(:all, :conditions => ['status = ?', Entry::STATUS_ACTIVE])
    end
  end

  def g
  end

  def lookup
  end

  def delete
    begin
      entry = Entry.find(params[:id])
      entry.destroy
    rescue ActiveRecord::RecordNotFound
    end
    render :nothing => true, :layout => false
  end

  def search
  end

  def logout
    reset_session
    cookies[:login] = nil
    redirect_to :action => :l
  end

  protected
  def authorized(u, p)
    u == 'greasepig' and p == 'preview'
  end

  def set_login_cookie
    cookies[:login] = { :value => 'true', :expires => 2.weeks.since(Time.now)}
  end

  def check_cookie
    cookies[:login] == 'true'
  end

  def delete_login_cookie(user_type)
    cookies.delete :login
  end

end
