class Entry < ActiveRecord::Base
  validates_presence_of :expression
  STATUS_ACTIVE = 1
  STATUS_INACTIVE = 0
end
