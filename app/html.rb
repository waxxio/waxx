module App::Html
  extend Waxx::Html
  extend self
      
  def render(x, title:"Untitled", content:nil, content_class:"container", message:{type:nil, message:nil}, css:[], js:[], js_ready: nil)
    x << head(x, title: title, css:css)
    x << nav1(x)
    x.res.error.each{|e|
      x << alert(e[:type], e[:message])
    }
    x << alert(message[:type], message[:message]) if message[:message]
    x << %(<div class="#{content_class}">#{content}</div>)
    x << foot(x, js:js, js_ready: js_ready)
  end

  def standard_css
    [
      "/lib/bootstrap4/css/bootstrap.min.css",
      "/lib/font/fira/fira.css",
      "/lib/font-awesome.min.css",
      "/lib/app.css",
    ]
  end

  def head(x, title:"Untitled", css:[])
    %(
      <!DOCTYPE html>
      <html lang="en"><head>
      <meta http-equiv="Content-Type" content="text/html; charset=UTF-8">
      <meta http-equiv="X-UA-Compatible" content="IE=edge">
      <meta name="http-equiv" content="text/html; charset=UTF-8">
      <meta name="keywords" content="">
      <meta name="viewport" content="width=device-width, initial-scale=1.0">
      <meta name="distribution" content="global">
      <link href="/media/favicon.png" rel="shortcut icon" type="image/png">
      #{(standard_css + css).map{|f| %(<link href="#{f}" rel="stylesheet">) }.join}
      <title>#{h title}</title>
      <script>var app={session:{person_id:#{x.usr['id'].to_i},company_id:#{x.usr['cid'].to_i},time:#{Time.now.to_i},config:{https_server:'#{Conf['site']['url']}'}}}</script>
      </head>
      <body id="oneaero">
    )
  end

  def usr_menu(x)
    return "" #if not x.usr?
    cls = %w(usr).include?(x.app) ? "active" : "" 
    cls = "active" if x.app == 'letter' and x.act == 'list'
    %(<a class="#{cls}" href="/dashboard"><span class="glyphicon glyphicon-cog"></span></a>)
  end

  def nav1(x)
    %(<div id="nav1"><a href="/part" class="">Parts</a><a href="/aog" class="">AOG</a><a href="/mro" class="">MRO</a><a href="/aircraft" class="on">Aircraft</a><a href="/directory" class="">Directory</a><a href="/industry" class="">Industry</a> <a href="/company" class="false">Admin</a></div><a id="logo" href="/" title="OneAero"><img src="/media/one.aero.logo-121x22-color.png" alt="OneAero Logo"></a>)
  end

  def nav2(x, data)
    %(<div id="nav2">
      #{data.map{|d| 
        href = d/:href ? d/:href : "/#{x.app}/#{d/:act}" 
        on = d/:act == x.act ? "on" : ""
        %(<a href="#{href}" class="#{on}">#{Waxx::Html.h d/:label}</a>)
      }.join}
    </div>)
  end

  def page(x, title:nil, content:nil, message:{type:"alert", message: nil}, css:[], js:[], js_ready:nil, nav2: [])
    render(x, title:(title || page['title']), content_class: "container", message: message, css: css, js: js, js_ready: js_ready, nav2: nav2, content:%(
      <h1>#{h title}</h1>
      #{content}
    ))
  end
  
  def admin(x, title:nil, content:nil, message:{type:"alert", message: nil}, css:[], js:[], js_ready:nil)
    render(x, title:title, content_class: "container", message: message, css: css, js: js, js_ready: js_ready, 
      content:%(
        #{admin_menu(x)}
        <div id="admin-panel">#{content}</div>
      )
    )
  end

  def admin_menu(x)
    re = [%(<!-- admin_menu -->\n<ul class="nav nav-tabs">)]
    re << [
      ["/portal","Home"],
      ["/issue","Issues"],
      ["/invoice","Billing"],
      ["/company","Clients","admin"],
      ["/usr","People","admin"],
      ["/content","Content","admin"],
      ["/website_page","Webpages","admin"]
    ].map{|m|
      next if m[2] and not x.group? m[2]
      cls = x.req.uri =~ /^#{m[0]}/ ? "active" : ""
      %(<li role="presentation" class="#{cls}"><a href="#{m[0]}">#{h m[1]}</a></li>)
    }.compact
    re << "</ul>"
    re.join("")
  end

  # Type can be: success info warning danger
  def alert(type="alert", message="")
    signs = {success:"info", info:"info", warning:"warning", danger:"warning"}
    return "" if message.empty?
    %(<div class="container"><div class="alert alert-#{type}" role="alert">
    <span class="glyphicon glyphicon-#{signs[type.to_sym]}-sign"></span> #{message.h}</div></div>)
  end

  def standard_js
    [
      "/lib/jquery-3.1.0.min.js",
      "/lib/bootstrap4/js/bootstrap.min.js",
      "/lib/number_format.js",
      "/lib/waxx.js",
      "/v4/app.js"
    ]
  end

  def quotes
    [
      ["Inspiration exists, but it has to find you working.","Pablo Picasso"],
      ["The glory of God is intelligence, or, in other words, light and truth.","God"],
      ["There is no great genius without some touch of madness.","Aristotle"],
      ["The intellect of the wise is like glass; it admits the light of heaven and reflects it.","Augustus Hare"],
      ["I not only use all the brains that I have, but all that I can borrow.","Woodrow Wilson"],                                                 
      ["Coming together is a beginning; keeping together is progress; working together is success.","Henry Ford"],                                                 
      ["Be excellent.","Gordon B. Hinckley"],                                                 
      ["We should not pretend to understand the world only by the intellect. The judgement of the intellect is only part of the truth.","Carl Jung"],
      ["There are no great limits to growth because there are no limits of human intelligence, imagination, and wonder.","Ronald Reagan"],
      ["Creativity is intelligence having fun.","Albert Einstein"]
    ]
  end

  def foot(x, js:[], js_ready:"")
    links = [
      ["/about","About OneAero"],
      ["/join","Join OneAero"],
      ["/contact","Contact Us"],
      ["/about/faq","FAQs"],
      ["/about/privacy","Privacy"],
      ["/about/terms","Terms &amp; Conditions"],
    ]
    links << (x.usr? ? ["/usr/logout","logout"] : ["/usr/login?return_to=#{qs x.req.uri}","login"])
    %(
    <footer>
      <div>OneAero Sales and Support: <b>+1 (855) ONE.AERO</b> or <b>+1 (720) 310-1200</b></div>
      <div class="text-sm">
        #{links.map{|l| %(<a href="#{l[0]}">#{l[1]}</a>)}.join("<span> • </span>")}
      <div class="text-sm text-muted">The OneAero logo is a registered trademark of OneAero Inc.</div>
      <div class="text-xs text-muted">Copyright &copy; 2016 OneAero Inc. All rights reserved.</div>
      <div class="text-xs text-muted">Processed in 13 ms.</div>
    </footer>
    #{modal}
    #{(standard_js + js).map{|f| %(<script src="#{f}" type="text/javascript"></script>) }.join}
    <script type="text/javascript">
      $(function(){
        app.usr.id = #{x.usr['id']} 
        app.usr.cid = #{x.usr['cid']}
        app.host = '#{x.req.env['Host']}'
        $('body').on("click","a",waxx.href);
        $(window).on("popstate",waxx.href);
        waxx.runURI();
        #{js_ready}
      })
    </script>
    #{piwik}
    </body>
    </html>
    )
  end

  def modal
  %(
  <div id="modal" class="modal fade">
    <div class="modal-dialog" role="document">
      <div class="modal-content">
        <div class="modal-header">
          <button type="button" class="close" data-dismiss="modal" aria-label="Close">
            <span aria-hidden="true">&times;</span>
          </button>
          <h4 class="modal-title">Modal title</h4>
        </div>
        <div class="modal-body">
          <p>One fine body&hellip;</p>
        </div>
        <div class="modal-footer">
          <button type="button" class="btn btn-secondary" data-dismiss="modal">Close</button>
          <button type="button" class="btn btn-primary">Save changes</button>
        </div>
      </div>
    </div>
  </div>
  )
  end

  def human_check(x)
    return '<input type="hidden" name="bot_check" id="bot_check" value="heart">' if x.usr?
    %(
      <div class="form-group">
        <input type="hidden" name="bot_check" id="bot_check" value="yes">
        <label class="">Have a Heart?</label>
        <div class="text-muted" style="margin-bottom: 4px;">
          Click on the heart <span class="glyphicon glyphicon-heart"></span> to show you are a person</div>
        <div id="bot_nav">
          #{%w(bell cloud heart flag plane leaf).map{|i|
            %(<button id="#{i}" type="button" onclick="app.humanClick('#{i}')" class="btn-lg lpad btn btn-link"><span class="glyphicon glyphicon-#{i}"></span></button>)
          }.join}
        </div>
      </div>
    )
  end

end


