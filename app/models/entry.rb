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
      puts "trying #{url}"
      doc = Hpricot(open(url))
      labels = (doc/"label")
      for label in labels
        next unless (label/"font")
	logger.debug("trying #{label.inner_html}")
         
        if /(#{self.expression}) 【(.*?)】<\/font> (.*)$/.match(label.inner_html)
          logger.debug("***found a match in #{label.inner_html}")
          self.reading = $2
          self.definition = $3
          break
        end 
      end
    end
  end
end
