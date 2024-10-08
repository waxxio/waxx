module App::Usr 
  extend Waxx::Pg
  extend self

   has(
    id:                   {type: "integer",label:"ID"},
    usr_name:             {type: "character",label:""},
    password_sha256:      {type: "character",label:""},
    salt_aes256:          {type: "character",label:""},
    failed_login_count:   {type: "smallint",label:""},
    require_new_password: {type: "smallint",label:""},
    password_mod_date:    {type: "date",label:""},
    last_login_host:      {type: "character",label:""},
    last_login_date:      {type: "timestamp",label:""},
    create_date:          {type: "timestamp",label:""},
    mod_date:             {type: "timestamp",label:""},
    create_by_id:         {type: "integer",label:""},
    mod_by_id:            {type: "integer",label:""},
    key:                  {type: "character",label:""},
    key_sent_date:        {type: "timestamp",label:""}
  )

  # Create the first usr (or any usr). Run from the console: App::Usr.init(x)
  def init(x)
    data = {}
    puts "Create a new user"
    print "Email: "
    data[:usr_name] = gets.chomp
    print "Password: "
    data[:password] = gets.chomp
    salt, encrypted_password = salt_password(x, data/:password)
    data[:salt_aes256] = salt
    data[:password_sha256] = encrypted_password
    u = post(x, data, returning: 'id')
    puts "User #{data/:usr_name} added (usr.id: #{u['id']})"
  end

  def login(x, usr_name, password)
    u = usr(x, usr_name:usr_name)
    return false, "Invalid user name", {} if u.nil? or u['id'].nil?
    pass = password?(u, password, u['salt_aes256'])
    return false, "Invalid password", {} if pass == false
    login_successful(x, u)
    return true, "Login successful", u
  end

  def record(x, id:0)
    get_by_id(x, id, "id, usr_name, password_sha256, last_login_date, last_login_host, password_mod_date")
  end

  def usr(x, usr_name:'', id:0)
    x.db.exec("
      SELECT id, company_id, usr_name, password_sha256, salt_aes256, last_login_date, last_login_host
      FROM usr 
      WHERE usr_name = $1 
      OR usr.id = $2 
      LIMIT 1", [usr_name, id]).first #rescue {}
  end
  
  def password?(u, password, salt)
    #u['password_sha256'] == Digest::SHA256.hexdigest(App.decrypt(salt) + password)
    u['password_sha256'] == Digest::SHA256.hexdigest(Conf['encryption']['old_key'] + password)
  end

  def salt_password(x, password)
    salt = Waxx.random_string(32, :any)
    [App.encrypt(salt), Digest::SHA256.hexdigest(salt + password)]
  end

  def set_password(x, id, password)
    salt, epw = salt_password(x, password)
    put(x, id, {salt_aes256: salt, password_sha256: epw})
  end

  def create(x, data={}, returning: "id")
    data = blk.call if block_given?
    salt, encrypted_password = salt_password(x, data/:password)
    data[:salt_aes256] = salt
    data[:password_sha256] = encrypted_password
    post(x, data, returning: returning)
  end

  def login_successful(x, usr)
    Waxx.debug "login_successful"
    x.db.exec("
      update usr set 
      last_login_date = now(), 
      last_login_host = $1,
      failed_login_count = 0
      where usr_name = $2", 
      [
        x.req.env['X-Forwarded-For'], 
        usr['usr_name']
      ]
    )
    set_cookies(x, usr)
    debug x.ua.inspect
  end                  

  def key_for_reset(x, id)
    x.db.exec("
      update usr set 
      key = generate_key(), 
      key_sent_date = now()
      where id = $1
      returning key", 
      [ id ]
    ).first['key']
  end                  

  def set_cookies(x, usr)
    x.usr['id'] = usr['id']
    x.usr['cid'] = usr['company_id']
    x.usr['grp'] = groups(x, usr['id']).push("user")
    x.usr['uk'] = Waxx.random_string(20) # The Update Key is used to protect against CSRF
    x.usr['la'] = Time.now.to_i # Last Activity used for session expiration
    x.ua['id'] = usr['id'] 
    x.ua['cid'] = usr['company_id']
    x.ua['un'] = usr['usr_name'] 
    x.ua['rm'] = x['remember_me'].to_i # Remember the user name for the login or UI features 
    x.ua['ll'] = Time.now.to_i # Last Login used for session expiration and welcome back
  end

  def groups(x, usr_id)
    x.db.exec("
    SELECT name 
    FROM grp JOIN usr_grp ON grp.id = usr_grp.grp_id
    WHERE usr_grp.usr_id = $1",[usr_id]).column_values(0)
  end

  runs(
    default: "list",
    home: {
      desc: "The home page of a logged in usr",
      acl: "user",
      get: proc{|x, *args|
        usr = by_id(x, x.usr['id'])
        person = App::Person.by_id(x, x.usr['id'])
        App::Html.render(x, 
          title: "#{person['first_name']} #{person['last_name']}", 
          content: App::Usr::Html.home(x, usr: usr, person: person)
        )
      }
    },
    list: {
      desc: "List users",
      acl: %w(admin),
      get: lambda{|x| List.run(x) }
    },
    record: {
      desc: "Edit a usr record",
      acl: %w(admin),
      get: lambda{|x, id, *args| Record.run(x, id:id) },
      post: lambda{|x, id, *args| Record.save(x, id:id, data:x.req.post) }
    },
    login: {
      desc: "Login",
      get: proc{|x, *args|
        #App::Html.page(x, title: "Login to #{Conf['site']['name']}", content: App::Usr::Html.login(x))
        x.res.redirect "/app/login?return_to=#{Waxx::Html.qs x.req.uri}"
      },
      post: proc{|x, *args|
        success, message, u = login(x, x['usr_name'], x['password'])
        if success
          if x.ext == 'json'
            x.res['Content-Type'] = "application/json"
            x << { success: success, message: message, usr: usr, key: key }.to_json
          else
            if x['return_to'].to_s[0] == '/'
              x << %(<html><script>location = '#{x['return_to']}';</script></html>)
            else
              x << %(<html>Error: Must return to a local path. Attempted return_to: #{x['return_to'].to_s.h}</html>)
            end
            # Some browsers not storing cookies on redirect
            #x.res.status = 302
            #x.res['Location'] = x['return_to']
          end
        else
          if x.ext == 'json'
            x.res['Content-Type'] = "application/json"
            x << { success: success, message: message, usr: usr, key: key }.to_json
          else
            App::Html.page(x, title: "Login Error", message:{type:"danger", message: message}, content: App::Usr::Html.login(x, return_to:x['return_to']))
          end
        end
      }
    },
    logout: {
      desc: "Logout of the app",
      get: proc{|x|
        x.usr['id'] = nil
        x.usr['grp'] = nil
        if x.ext == "json"
          x << %({"success":true})
        else
          x.res.status = 302
          x.res['location'] = '/'
        end
      }
    },
    password_reset:{
      desc: "Send the user a password reset link.",
      post: proc{|x, *args|
        # See if the user exists
        u = App::Usr.usr(x, usr_name: x['email'])
        if u.nil?
          # Send an email that we do not have an account for that user
          App::Email.post(x, Email.email_not_found(x, x['email']))
        else
          # Send the password reset email
          k = App::Usr.key_for_reset(x, u['id'])
          App::Email.post(x, Email.password_reset(x, u, k))
        end
        App::Html.page(x, title:"Password Reset Sent", content:"A link to reset your password has been sent to #{x['email'].h}. Please check your email. (It may be in your Spam or Junk folder.)")
      }
    },
    password: {
      desc: "Form to select a new password",
      get: lambda{|x, id=nil, key=nil, *args|
        if id.nil? and not x.usr?
          return App.login_needed(x)
        end
        if key.nil? and not x.usr?
          return App.login_needed(x)
        end
        if x.usr?
          App::Html.render(x, title: "Reset Password", content:Html.change_password(x))
        else
          u = App::Usr.get_by_id(x, id, "usr_name, key, key_sent_date")
          if u['key'] != key
            return App.error(x, title:"Link Invalid", 
              message:"The link you are using does not match our records. 
              If you requested a password reset multiple times today, 
              please use the most recent link that you received. If that does 
              not work, please request another link on the login page.")
          end
          if u['key_sent_date'] < Time.new - 21600 # 6 hours
            return App.error(x, title:"Link Expired", 
              message:"The link you are using expired after 6 hours to protect 
              your account. Please request another link on the login page.")
          end
          App::Html.page(x, title: "Reset Password", content:Html.change_password(x, u, key))
        end
      },
      post: lambda{|x, id=nil, key=nil, *args|
        if x['password1'] != x['password2']
          return App::Html.render(x, title: "Reset Password", content:Html.password_form(x), message:{type:"danger", message:"Your passwords do not match. Please try again."})
        end
        if x['password1'] =~ /[a-z]|[A-Z]/
          return App::Html.render(x, title: "Reset Password", content:Html.password_form(x), message:{type:"danger", message:"Your passwords do not match. Please try again."})
        end
        if id.nil? and x.usr?
          App::Usr.set_password(x, x.usr['id'], x["password1"])
          App::Html.page(x, title:"Password Reset Successful", content:"Your password has been reset.")
        elsif id and key
          u = App::Usr.get_by_id(x, id, "usr_name, key, key_sent_date")
          if u['key'] != key
            return App.error(x, title:"Link Invalid", 
              message:"The link you are using does not match our records. 
              If you requested a password reset multiple times today, 
              please use the most recent link that you received. If that does 
              not work, please request another link on the login page.")
          end
          App::Usr.set_password(x, id, x["password1"])
          success, message, u = App::Usr.login(x, u['usr_name'], x['password1'])
          App::Html.page(x, title:"Password Reset Successful", content:"Your password has been reset and you have been logged in.")
        end
      }
    }
  )
end

require_relative 'html'
require_relative 'email'
require_relative 'password'
require_relative 'record'
require_relative 'list'
