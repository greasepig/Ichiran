# Filters added to this controller apply to all controllers in the application.
# Likewise, all the methods added will be available for all controllers.

class ApplicationController < ActionController::Base
  helper :all # include all helpers, all the time
  helper_method :keitai_browser
  # See ActionController::RequestForgeryProtection for details
  # Uncomment the :secret if you're not using the cookie session store
  protect_from_forgery # :secret => 'e7f22577ffc69aed98eb3ce0da3321b5'
  
  # See ActionController::Base for details 
  # Uncomment this to filter the contents of submitted sensitive data parameters
  # from your application log (in this case, all fields with names like "password"). 
  # filter_parameter_logging :password
  before_filter :set_locale
  before_filter :log_browser
  def set_locale
    # if this is nil then I18n.default_locale will be used
    langs = accepted_languages
    I18n.locale = params[:locale] || (langs and langs[0] ? langs[0][0] : nil)
  end
  protected :set_locale
  def log_browser
   logger.info "user agent = '#{request.env["HTTP_USER_AGENT"]}'" 
  end
  protected :log_browser

  def accepted_languages
    # no language accepted
    return [] if request.env["HTTP_ACCEPT_LANGUAGE"].nil?
    
    # parse Accept-Language
    accepted = request.env["HTTP_ACCEPT_LANGUAGE"].split(",")
    accepted = accepted.map { |l| l.strip.split(";") }
    accepted = accepted.map { |l|
      if (l.size == 2)
        # quality present
        [ l[0].split("-")[0].downcase, l[1].sub(/^q=/, "").to_f ]
      else
        # no quality specified =&gt; quality == 1
        [ l[0].split("-")[0].downcase, 1.0 ]
      end
    }
    
    # sort by quality
    accepted.sort { |l1, l2| l2[1] <=> l1[1] }
  end

  def keitai_browser
    /Softbank/.match(request.env["HTTP_USER_AGENT"])
  end
end
