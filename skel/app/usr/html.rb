module App::Usr::Html
  extend Waxx::Html
  extend self

  def home(x, usr:{}, person:{})
    %(
      <div class="row">
        <div class="col-md-3 nav2">#{App::Person::Html.nav2(x)}</div>
        <div class="col-md-8">
          <h1>#{person['first_name'].h} #{person['last_name'].h}</h1>
          <div>#{usr['usr_name'].h}</div>
          <div>#{person['phone'].h}</div>
        </div>
      </div>
    )
  end

  def login(x, return_to:"/")
    %(
      <div class="container">
      <h1>Client Portal</h1>
      <div class="row">
        <div class="col-md-4">#{login_form(x, return_to:return_to)}</div>
        <div class="col-md-8">#{App::WebsitePage.by_uri(x, uri:"/portal")['content']}</div>
      </div>
      </div>
    )
  end

  def login_form(x, return_to: "/")
    %(
      <form action="/usr/login" method="post">
        <!--#{Waxx::Csrf.ht(x)}-->
        <input type="hidden" name="return_to" value="#{h return_to}">
        <div class="form-group">
          <label for="usr_name">Email</label>
          <input type="email" class="form-control" id="usr_name" name="usr_name" placeholder="" value="#{x.ua['un'] if x.ua['rm']}">
        </div>
        <div class="form-group">
          <label for="password">Password</label>
          <input name="password" type="password" class="form-control" id="password" placeholder="">
        </div>
        <div class="checkbox">
          <label><input name="remember_me" type="checkbox" #{"checked" if x.ua['rm']} value="1"> Remember me </label>
        </div>
        <button type="submit" class="btn btn-primary">Login</button>
      </form>
      <p style="margin-top: 2em;"><a href="#password_reset_form" onclick="$('#password_reset_form').toggle('blind')">Forgot password?</a></p>
      <div id="password_reset_form" style="display:none;">
        <form action="/usr/password_reset" method="post">
          <!--#{Waxx::Csrf.ht(x)}-->
          <div class="form-group">
            <label for="email">Enter your email address</label>
            <input type="email" class="form-control" id="email" name="email" placeholder="you@example.com" value="#{x.ua['un'] if x.ua['rm'] == 1}">
          </div>
          <button type="submit" class="btn btn-warning">Send Password Reset Link</button>
        </form>                       
      </div>
    )
  end

  def change_password(x, u=nil, key=nil)
    content = App::Content.by_slug(x, slug: "password-rules")
    %(
    <div class="row">
      <div class="col-md-3 nav2">#{App::Person::Html.nav2(x) if x.usr?}</div>
      <div class="col-md-5">
        <h1>Change Password</h1>
        <form action="" method="post">
          #{Waxx::Csrf.ht(x)}
          <div class="form-group">
            <!-- <label for="usr_name">User Name</label> -->
            #{h(u ? u['usr_name'] : x.ua['un'])}
          </div>
          #{new_password_field(x)}
          <button type="submit" class="btn btn-primary" id="btn-submit" disabled="disabled">Change Password</button>
        </form>
      </div>
    </div>
    )
  end

  def new_password_field(x)
    %(
      <div class="form-group">
        <label for="password">Password</label>
        <input name="password1" type="password" class="form-control" id="pw1" onkeyup="app.passwordNew('#pw1', '#pw2', '#btn-submit');">
        <div class="text-muted">Score 60+. Use upper &amp; lower case, numbers, and symbols.</div> 
        <div class="text-muted">Score: <span id="pw1-status" style="color:#000; font-weight: normal;">0 Continue</span></div>
        <div style="border: 1px solid #ccc; background-color:#eee;">
          <div id="pw1-meter" style="height: 4px; width:0; background-color:red;color:white;overflow:visible;font-size:9px;"></div>
        </div>
      </div>
      <div class="form-group">
        <label for="password">Confirm Password <span id="pw2-icon" class="glyphicon glyphicon-unchecked"></span></label>
        <input name="password2" type="password" class="form-control" id="pw2" onkeyup="app.passwordNew('#pw1', '#pw2', '#btn-submit');">
      </div>
    )
  end

  def list(x, usrs)
    re = [%(<table class="table">
    <tr><th>ID</th><th>User Name</th><th>Last Login</th><th>Failed Logins</th></tr>
    )]
    re << usrs.map{|u|
      %(<tr><td>#{u/:id}</td>
      <td>#{u/:usr_name}</td>
      <td>#{u['last_login_date'].f("%d-%b-%Y @%H:%M")} from #{u/:last_login_host}</td>
      <td>#{u/:failed_login_count}</td>
      </tr>)
    }
    re << %(</table><a href="/usr/record/0" class="btn btn-success"><span class="glyphicon glyphicon-plus"></span> Add User</a>)
    re.join
  end
end
