#!/usr/bin/env ruby

require 'chef'

config_object = Chef::Config.from_file("/Users/jcowie/.chef/knife.rb")

rest_object = Chef::REST.new(Chef::Config[:chef_server_url])

search_result = rest_object.get_rest("/search/node?q=chef_environment:libmemcached_upgrade")

puts search_result