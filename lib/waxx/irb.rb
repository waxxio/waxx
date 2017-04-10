# Waxx Copyright (c) 2016 ePark labs Inc. & Daniel J. Fitzpatrick <dan@eparklabs.com> All rights reserved.
# Released under the Apache Version 2 License. See LICENSE.txt.

# Thanks to http://jasonroelofs.com/2009/04/02/embedding-irb-into-your-ruby-application/

require 'irb'

module IRB # :nodoc:
  def self.xstart_session(binding)
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
  def self.start_session(context)
		IRB.setup(nil)
		workspace = IRB::WorkSpace.new(context)
		irb = IRB::Irb.new(workspace)
		IRB.conf[:MAIN_CONTEXT] = irb.context
		irb.eval_input
  end
end
