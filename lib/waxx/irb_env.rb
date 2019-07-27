# Waxx Copyright (c) 2016 ePark labs Inc. & Daniel J. Fitzpatrick <dan@eparklabs.com> All rights reserved.
# Released under the Apache Version 2 License. See LICENSE.txt.

extend Waxx::Console

puts "Welcome to Waxx"
puts "See waxx.io for more info"
puts ""
puts "HTTP Methods with URI: "
puts "  get '/app/env'"
puts "  post '/person/record/1?first_name=Jane;last_name=Lee'"
puts "  (This will set the first & last name of person 1.)"
puts ""
puts "Pass 'x' to all data methods: "
puts "  App::Person::Record.get(x, id: 1)"
puts "  App::Person::Record.post(x, {first_name:'Jane', last_name: 'Lee'})"
puts "  App::Person::Record.put(x, 1, {first_name:'Joe', last_name: 'Bar'})"
puts ""
