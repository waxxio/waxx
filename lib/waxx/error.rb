# Waxx Copyright (c) 2016 ePark labs Inc. & Daniel J. Fitzpatrick <dan@eparklabs.com> All rights reserved.
# Released under the Apache Version 2 License. See LICENSE.txt.

module Waxx::Error
  def error(x, status:200, type:nil, title:"An error occurred", message:"", args: [])
     x.res.status = status
     App[:app_error][type.to_sym][:get].call(x, title, message, *args)
  end
  
  def fatal(x, e)
    App::AppLog.log(x, cat: "Error", name:"#{x.req.uri}", value: "#{e}\n#{e.backtrace}")
    x.res.status = 503
    er = [
      "ERROR:\n#{e}\n#{e.backtrace.join("\n")}",
      "USR:\n\n#{x.usr.map{|n,v| "#{n}: #{v}"}.join("\n")}",
      "GET:\n#{x.req.get.map{|n,v| "#{n}: #{v}"}.join("\n")}",
      "POST:\n#{req.post.map{|n,v| "#{n}: #{v}"}.join("\n")}",
      "ENV:\n\n#{x.req.env.map{|n,v| "#{n}: #{v}"}.join("\n")}"
    ].join("\n\n")

    if App['debug']['on_screen']
      x << "<pre>#{er}</pre>"
    else
      get_const(App, x.ext).get(x,
        title: "System Error",
        content: "<h4><span class='glyphicon glyphicon-thumbs-down'></span> Sorry! Something went wrong on our end.</h4>
          <h4><span class='glyphicon glyphicon-thumbs-up'></span> The tech support team has been notified.</h4>
          <p>We will contact you if we need addition information. </p>
          <p>Sorry for the inconvenience.</p>"
      )
    end
    if App['debug']['send_email'] and App['debug']['email']
      to_email = App['debug']['email']
      from_email = App['site']['support_email']
      subject = "[Bug] #{App['site']['name']} #{x.meth}:#{x.uri}"
      body = er
      begin
        # Send email via DB.email table
        App::Email.post(x,{
          to_email: to_email,
          from_email: from_email,
          subject: subject,
          body: body
        })
      rescue => e2
        begin
          # Only send email
          Mail.deliver do
            from     from_email
            to       to_email
            subject  subject
            body     body
          end
        rescue => e3
           puts "FATAL ERROR: Could not send bug report email: #{e2}\n#{e2.backtrace} AND #{e3}\n#{e3.backtrace}"
        end
      end
    end
  end
end
