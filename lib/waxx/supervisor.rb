# Waxx Copyright (c) 2016 ePark labs Inc. & Daniel J. Fitzpatrick <dan@eparklabs.com> All rights reserved.
# Released under the Apache Version 2 License. See LICENSE.txt.

# Supervises the thread pool
module Waxx::Supervisor
  extend self
 
  ##
  # Check the thread pool and add or remove threads
  def check
    start_threads = Conf['server']['start_threads'] || Conf['server']['threads']
    max_threads = Conf['server']['max_threads'] || Conf['server']['threads']
    idle_thread_timeout = Conf['server']['idle_thread_timeout'] || 600
    ts = Thread.list.select{|t| t[:name] =~ /waxx/}
    debug "Supervisor.check_threads: #{ts.size}"
    # Ensure the minimum threads
    if ts.size < start_threads
      0.upto(start_threads - ts.size).each do |i|
        Waxx::Server.create_thread(i)
      end
    end
    # If no idle threads add more (up-to max)
    if ts.size < max_threads
      idle_count = 0
      ts.each{|t|
        idle_count += 1 if t[:status] == 'idle'
      }
      if idle_count == 0
        Waxx::Server.create_thread(1)
      end
    end
    # Terminate old threads
    ts.each{|t|
      if ts.size > start_threads
        if Time.new.to_i - t[:last_used].to_i > idle_thread_timeout and t[:status] == 'idle' and Thread.current != t
          debug "Terminate expired thread #{t[:name]}"
          Conf['databases'].each{|n,v|
            t[:db][n.to_sym].close rescue "already closed"
          }
          t.exit
          ts.delete t
        end
      end
    }
  end

end
