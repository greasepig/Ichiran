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
#      labels = (doc/"label")
      labels = (doc/"div")
      for label in labels
        next unless (label/"font")
         
        if /(#{self.expression}\b.*?)【(.*?)】<\/font> (.*)$/.match(label.inner_html)
          logger.debug("***found a match in #{label.inner_html}")
          self.expression = $1
          self.reading = $2
          if $3 and !self.definition
            self.definition = $3.gsub(/<\/?[^>]*>/, "")
            self.definition = self.definition.gsub(/\(P\) ?/, "")
            self.definition = self.definition.gsub(/\(See.*?\) ?/, "")
            self.definition = self.definition.gsub(/\[.*?\] ?/, "")
          end
          break
        elsif  /(#{self.expression}\b.*?) <\/font> (.*)$/.match(label.inner_html)
          # definition only (hiragana or katakana)
          logger.debug("***found a match in #{label.inner_html}")
          self.expression = $1
          self.reading = ''
          if $2 and !self.definition
            self.definition = $2.gsub(/<\/?[^>]*>/, "")
            self.definition = self.definition.gsub(/\(P\) ?/, "")
            self.definition = self.definition.gsub(/\(See.*?\) ?/, "")
            self.definition = self.definition.gsub(/\[.*?\] ?/, "")
            self.definition = self.definition.strip
          end
        end 
      end
    end
  end

  def get_j_def
    definition = nil
    if self.expression
      url = "http://www.sanseido.net/User/Dic/Index.aspx?TWords=" + CGI.escape(self.expression) + "&st=1&DailyJJ=checkbox"
      data = "TWords=" + CGI.escape(self.expression) + "&st=1&DailyJJ=checkbox"
      path = "/User/Dic/Index.aspx?#{data}"
      http = Net::HTTP.new('www.sanseido.net', 80)
      @headers = {
        'Content-Type' => 'application/x-www-form-urlencoded',
        'User-Agent' => USERAGENT
      }
      resp, data2 = http.get2(path, @headers)
#      doc = Hpricot(open(url))
      doc = Hpricot(resp.body)
      div = doc.search("//div[@class='NetDicBody']")
      definition = div.inner_html
      definition = definition.sub(/.*?<br \/>/, "") # remove everything up to and including the first break
      definition = definition.sub(/<br \/>.*$/m, "")  # remove the next break and everything after it
      definition = definition.gsub(/<\/?[^>]*>/, "")  # remove all the tags
      definition = definition.gsub(/〈\/?[^〉]*〉/, "") # remove the dictionary names
      definition = definition.gsub(/[\n\r]/, "") # remove all line breaks
      definition = definition.gsub(/^[\s]*\b/, "") # remove all spaces at the beginning
    end
    return definition
  end

  def all_fields_available?
    !self.expression.blank? and !self.definition.blank?
  end
end
