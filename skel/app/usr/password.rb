module App::Usr::Password
  extend self

  def send_email(x)
    App::Email.post(x,
      to_email: x['usr_name'],
      from_email: Conf['site']['support_email'],
      from_name: Conf['site']['name'],
      subject: "Password Reset",
      body_text: ["You requested a password reset for #{Conf['site']['name']}.",
        "If you did not request a password reset, please ignore this email.",
        "\n\nThe link below is valid for 3 hours.",
        "Please click this link to reset your password:\n\n",
        "  #{Conf['site']['url']}/usr/password/#{u['usr_id']}/#{u['key']}",
        "\n\nThank you,\n\nThe #{Conf['site']['name']} Team"
        ].join
    )
  end

  def text(x, usr, key, as)
    %(
    Hopefully it was you who requested a password reset for #{Conf['site']['name']}. 
    If you did not request a password reset, please ignore this email.
    
    The link below is valid for 3 hours. 
    Please click the link to reset your password: 
    
      #{Conf['site']['url']}/usr/password/#{usr['usr_id']}/#{key}
    
    Please reply to this email if you need any help or have any questions.

    Thank you,
    
    The #{Conf['site']['name']} Team
    )
  end

  def html

  end

  def post(x)
    # See if the user exists
    u = App::Usr.usr(x, usr_name: x['usr_name'])
    if u['usr_id'].to_i > 0
      k = App::Usr.key_for_reset(x, u['usr_id'])
      App::Html.page(x, title:"Password Reset Sent", content:"A link to reset your password has been sent to #{x['email'].h}. Please check your email. (It may be in your SPAM folder.)")
    else

    end

  end

end
