require 'rubygems'
require 'sinatra'
require 'dbi'
require 'pp'

disable :show_exceptions

mysql_user = 'mysqlchkuser'
mysql_pass = 'mysqlchkpass'

get '/status' do
  sql = 'show databases'
  begin
    dbh = DBI.connect('dbi:Mysql:mysql:localhost', mysql_user, mysql_pass)
    result = dbh.select_all sql
  rescue  DBI::DatabaseError => e
    pp "[WARN] MySQL is gone... - [ #{Time.new.to_s} ]"
    halt 503, 'MySQL is gone...'
  end

  if result.nil?
    pp "[WARN] MySQL is *DOWN* - [ #{Time.new.to_s} ]"
    halt 503, 'MySQL is *DOWN*'
  else
    "MySQL is running\r\n"
  end
end

['/repl', '/dbs'].each do |path|
  get path do
    sql = 'show slave status'
    begin
      dbh = DBI.connect('dbi:Mysql:mysql:localhost', mysql_user, mysql_pass)
      sth = dbh.execute sql
      result = sth.fetch_hash
      sth.finish
    rescue  DBI::DatabaseError => e
      pp "[WARN] MySQL is gone... - [ #{Time.new.to_s} ]"
      halt 503, 'MySQL is gone...'
    end
  
    check_variables = ['Slave_IO_Running','Slave_SQL_Running','Seconds_Behind_Master']
    slave_io, slave_sql, seconds_behind = check_variables.map{|key| result[key]}
    status = <<-"EOS"
    
    Slave_IO_Running: #{slave_io}
    Slave_SQL_Running: #{slave_sql}
    Seconds_Behind_Master: #{seconds_behind}
    EOS
   
    if slave_io == "Yes" && slave_sql == 'Yes' && seconds_behind.to_i <= 1
      "MySQL replication is fine\r\n"
    else
      pp "[WARN] MySQL replication is *DOWN* - [ #{Time.new.to_s} ] + #{status}"
      halt 503, 'MySQL replication is *DOWN*'+status
    end 
  end
end
