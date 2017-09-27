module App::Usr::Email
  extend Waxx::Html
  extend self

  def password_reset(x, u, k)
    { 
      to_email: u['usr_name'],
      from_email: Conf['site']['support_email'],
      from_name: Conf['site']['name'],
      subject: "Password Reset",
      body_text: password_reset_text(x, u, k),
      body_html: password_reset_html(x, u, k)
    }
  end

  def email_not_found(x, email)
    { 
      to_email: email,
      from_email: Conf['site']['support_email'],
      from_name: Conf['site']['name'],
      subject: "Account Not Found",
      body_text: email_not_found_text(x)
    }
  end
  
  def email_not_found_text(x)
    App::Email::Email.text(x, title: "Email Address Not Found", content: %(
We received a request to reset your password on #{h Conf['site']['name']}.
      
Unfortunately, we do not have an account with your email address. Please setup your account here:",
      
    #{Conf['site']['url']}
      
If you did not request a password reset, please disregard this email. Most likely someone else mistyped their email.
      
#{App::Email::Email.support_signature_text(x)}
    ))

  end

  def password_reset_text(x, u, k)
    App::Email::Email.text(x, title: "Password Reset", content: %(
We received a request to reset your password on #{h Conf['site']['name']}.
      
Please click the link below to change your password. The link is valid for six hours.
      
    #{Conf['site']['url']}usr/password/#{u['usr_id']}/#{k}
      
If you did not request a password reset, please disregard this email. Most likely someone else mistyped their email.
      
#{App::Email::Email.support_signature_text(x)}
    ))

  end

  def password_reset_html(x, u, k)
    App::Email::Email.html(x, title: "Password Reset", content: %(
      <p>We received a request to reset your password on #{h Conf['site']['name']}.</p>
      <p>Please click the link below to change your password. The link is valid for six hours.</p>
      <p><a href="#{Conf['site']['url']}usr/password/#{u['usr_id']}/#{k}">Reset Password</a></p>
      <p>If you did not request a password reset, please disregard this email. Most likely someone else mistyped their email.</p>
      #{App::Email::Email.support_signature_html(x)}
    ))
  end

end
