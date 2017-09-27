# Waxx Copyright (c) 2016 ePark labs Inc. & Daniel J. Fitzpatrick <dan@eparklabs.com> All rights reserved.
# Released under the Apache Version 2 License. See LICENSE.txt.

# Thanks to http://jasonroelofs.com/2009/04/02/embedding-irb-into-your-ruby-application/

require 'irb'

# Jump into an IRB session with `waxx console`
module IRB
  ##
  # Start an IRB session for Ruby < 2.4
  def self.start_session_old(binding)
    unless @__initialized
      args = ARGV
      ARGV.replace(ARGV.dup)
      IRB.setup(nil)
      ARGV.replace(args)
      @__initialized = true
    end

    workspace = WorkSpace.new(binding)

    irb = Irb.new(workspace)

    @CONF[:IRB_RC].call(irb.context) if @CONF[:IRB_RC]
    @CONF[:MAIN_CONTEXT] = irb.context

    catch(:IRB_EXIT) do
      irb.eval_input
    end
  end

  ##
  # Start an IRB session
  # `waxx console`
  def self.start_session(context)
    return self.start_session_old(context) if RUBY_VERSION.to_f < 2.4
    IRB.setup(nil)
    workspace = IRB::WorkSpace.new(context)
    irb = IRB::Irb.new(workspace)
    IRB.conf[:MAIN_CONTEXT] = irb.context
    irb.eval_input
  end
end
