require 'open-uri'
require 'hpricot'
class Entry < ActiveRecord::Base
  validates_presence_of :expression
  STATUS_ACTIVE = 1
  STATUS_INACTIVE = 0
  before_create :add_def_and_reading

  def add_def_and_reading
    if self.expression
      url = "http://www.aa.tufs.ac.jp/~jwb/cgi-bin/wwwjdic.cgi?1MUJ" + CGI.escape(self.expression) + "_3_10_5_ivory_black_0"
      logger.debug "trying #{url}"
      doc = Hpricot(open(url))
      labels = (doc/"label")
      for label in labels
        next unless (label/"font")
         
        if /(#{self.expression}\b.*?)【(.*?)】<\/font> (.*)$/.match(label.inner_html)
          logger.debug("***found a match in #{label.inner_html}")
          self.expression = $1
          self.reading = $2
          if $3
	    self.definition = $3.gsub(/<\/?[^>]*>/, "")
            self.definition = self.definition.gsub(/\(P\) ?/, "")
          end
          break
        end 
      end
    end
  end

  def all_fields_available?
    !self.reading.blank? and !self.expression.blank? and !self.definition.blank?
  end
end
