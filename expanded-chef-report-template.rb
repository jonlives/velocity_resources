#!/usr/bin/env ruby

require 'chef'
require 'choice'
require 'json'
require 'net/smtp'
require 'uri'


#Here's the query to search for - change this if you want :)

query = "chef_environment:testing OR chef_environment:libmemcached_upgrade"
mail_from = "chef@yourcompany.com"

# You shouldn't need to change anything below here

#Set up command line options and assign to local vars
Choice.options do
  header ""
  header "Specific options:"
  
  option :knife_conf, :required => true do
      short '-c'
      long  '--knife_conf=PATH_TO_KNIFE_RB'
      desc  'Knife config file to use for restoring data'
  end
  
  option :mailto, :required => true do
      short '-m'
      long  '--mailto *ADDRESSES'
      desc  'Email addresses to send report to'
  end
end

knife_config = Choice.choices[:knife_conf]
report_recipients = Choice.choices[:mailto].map{|r| r + "<" + r + ">"}
results = []

#Load chef config and create our REST object to call against
Chef::Config.from_file(knife_config)  
int_rest = Chef::REST.new(Chef::Config[:chef_server_url])


#Run the seach against the REST object we created
puts "Running search #{query}..."
search_result = int_rest.get_rest(URI.escape("/search/node?q=#{query}"))
search_result["rows"].each do |r|
  #Don't keep nil results
  next if r.nil?
  next if !r.has_key?("fqdn")
  results <<  r.fqdn
end

#Generate a nicely formatted mail message with our recipients and results in it...
message = <<MESSAGE_END
From: #{mail_from} <#{mail_from}>
#{report_recipients.map{|r| "To: " + r}}
MIME-Version: 1.0
Content-type: text/html
Subject: Chef Report
<html
<head>
<style type="text/css">
table {border-collapse:collapse;}
table, td, th {border:1px solid black;padding:5px;}
</style>
</head>
<body>
<h2>Chef Report</h2>
<p>
#{results.size} nodes matched the search #{query} as of #{Time.now.strftime("%d/%m/%Y at %I:%M%p")}:
<p>
<table border=1>
<tr>
<th>Node</th>
</tr>
#{results.map{|r| "<tr><td>#{r}</td></tr>"}.join("\n")}
</table>
</body>
</html>
MESSAGE_END

# Then send it using smtp on localhost.
puts "Mailing report..."
Net::SMTP.start('127.0.0.1', 25) do |smtp|
  smtp.send_message message, "#{mail_from}", report_recipients
end