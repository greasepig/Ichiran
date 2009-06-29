require "net/http"
require "cgi"

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
      flash[:notice] = I18n.t :bad_login
      render :action => :l
    end
  end

  def e
    if params[:entry]
      entry = Entry.new(params[:entry]) 
      if params[:jdef]
        jdef = entry.get_j_def
        logger.debug ("Got #{jdef}")
        entry.definition = jdef if jdef
        logger.debug ("entry.definition = #{entry.definition}")
      end
      entry.save
      redirect_to :action => :e
    else
      @entries = Entry.find(:all, :conditions => ['status = ?', Entry::STATUS_ACTIVE], :order => 'created_at desc')
    end
  end

  def update
    @entry = Entry.find(params[:id])
    @entry.update_attributes(params[:entry])
    render :partial => 'entry_form'
  end

  def try
    @entry = Entry.find(params[:id])
    @entry.get_j_def
    redirect_to :action => :e
  end

  def delete
    begin
      entry = Entry.find(params[:id])
      entry.destroy
    rescue ActiveRecord::RecordNotFound
    end
    if request.xhr?
      render :nothing => true, :layout => false
    else
      redirect_to :action => :e
    end
  end

  def upload
    begin
      entry = Entry.find(params[:id])
    rescue ActiveRecord::RecordNotFound
    end
    if entry and entry.all_fields_available? and add_fact_to_anki(entry)
      entry.destroy
      if request.xhr?
        render :nothing => true, :layout => false
      else
        flash[:notice] = I18n.t(:successful_upload)
        redirect_to :action => :e
      end
    elsif entry.duplicate
        entry.destroy
        flash[:notice] = I18n.t(:entry_was_duplicate)
        redirect_to :action => :e
    else
      flash[:notice] = I18n.t(:upload_problem)
      e
      render :action => :e
    end
  end

  def upload_multi
    entries = Entry.find(:all, :conditions => ['status = ? and definition is not null', Entry::STATUS_ACTIVE], :order => 'created_at desc')
    count = 0
    duplicates = 0
    for entry in entries
      if entry.all_fields_available? and add_fact_to_anki(entry)
        entry.destroy
        count += 1 
      elsif entry.duplicate
        entry.destroy
        duplicates += 1 
      end
    end
    flash[:notice] = I18n.t(:multi_upload_message, :count => count, :duplicates => duplicates)
    redirect_to :action => :e
  end

  def search
  end

  def logout
    reset_session
    cookies[:login] = nil
    redirect_to :action => :l
  end

  protected
  def add_fact_to_anki(entry)
    if !session[:anki_cookie]
      login_to_anki
    end
    entry.reading ||= ''
    data = "Expression=#{CGI.escape(entry.expression)}&Meaning=#{CGI.escape(entry.definition)}&Reading=#{CGI.escape(entry.reading)}&action=Add"
    logger.debug("Using data #{data}")
    path = "/deck/edit"
    @http ||= Net::HTTP.new(ANKI_HOST, 80)
    @headers = {
      'Cookie' => session[:anki_cookie],
      'Content-Type' => 'application/x-www-form-urlencoded',
      'User-Agent' => USERAGENT
    }
    resp, data2 = @http.post2(path, data, @headers)
    logger.debug("Got response code #{resp.code}")
    entry.duplicate = true if /'Expression' is not unique/.match(resp.body)
    /Added OK!/.match(resp.body)
  end

  def login_to_anki
    @http ||= Net::HTTP.new(ANKI_HOST, 80)
    data = "username=#{CGI.escape(ANKI_USERNAME)}&password=#{CGI.escape(ANKI_PASSWORD)}"
    path = '/account/login'
    @headers = {
      'Content-Type' => 'application/x-www-form-urlencoded',
      'User-Agent' => USERAGENT
    }
    resp, data2 = @http.post2(path, data, @headers)
    session[:anki_cookie] = resp.response['set-cookie'].split('; ')[0] if resp and resp.response and resp.response['set-cookie']

  end

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
