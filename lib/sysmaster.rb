require 'rubygems'
require 'sequel'

module Sysmaster
  mattr_accessor :options, :DB

  def self.set_credentials(u, p)
    self.options ||= {}
    self.options[:credentials] = {:username => u, :password => p}
  end
  
  def self.execute(query, disconnect_after_execution = true)
    self.DB ||= self.connection rescue nil
    returner = self.DB[query] unless self.DB.nil? rescue nil
    self.DB.disconnect if disconnect_after_execution
    returner
  end
  
  def self.connection
    unless self.options.nil? or self.options[:credentials].nil?
      Sequel.odbc(
        'sysmaster',
        :user     => options[:credentials][:username],
        :password => options[:credentials][:password]
      )
    end
  end  
  
  
  # amount should be a float (ie.  10.00)
  def self.add_credit(id, amount)
    returner = self.connection["exec manager..sp_credit_member '', '', #{id}, #{amount}"].first[:untitled_1] rescue nil
    unless returner.nil?
      regexp = /INVOICE_ID:([0-9]+);/
      if returner =~ regexp
        returner = returner.match(regexp)[1] 
        returner = false if returner.to_i.zero?
      else
        returner = false
      end
    end
    returner
  end  
  
  def self.valid_id?(id)
    query = "SELECT acctid FROM member WHERE acctid=#{id}"
    (not self.execute(query).all.empty?) rescue nil
  end
  
  def self.authenticate_account(id, password)    
    query = "SELECT acctid FROM member WHERE acctid=#{id} AND password='#{password}'"
    (not self.connection[query].all.empty?) rescue nil
  end
  
  def self.find_member(id)
    self.execute("select * from member where acctid = #{id.to_i}").first
  end
end