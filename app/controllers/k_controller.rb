class KController < ApplicationController
  def l
  end

  def authenticate
    if authorized(params[:user], params[:password])
      set_login_cookie
      redirect_to :action => :e
    else
      flash[:notice] = t :bad_login
      render :action => :l
    end
  end

  def e
    Entry.create(params[:expression]) if params[:expression]
    @entries = Entry.find(:all, :conditions => ['status = ?', Entry::STATUS_ACTIVE])
  end

  def g
  end

  def lookup
  end

  def delete
  end

  def search
  end

  protected
  def authorized(u, p)
    u == 'greasepig' and p == 'preview'
  end

  def set_login_cookie
    cookies[:login] = { :value => 'true', :expires => 2.weeks.since(Time.now)}
  end

  def delete_login_cookie(user_type)
    cookies.delete :login
  end

end
