module App::Html
  extend Waxx::Html
  extend self
      
  def standard_css
    [
      "/lib/bootstrap/css/bootstrap.min.css",
      "/lib/bootstrap/css/carousel.css",
    ]
  end

  def standard_js
    [
      "/lib/jquery-3.1.0.min.js",
      "/lib/bootstrap/js/bootstrap.min.js",
      "/app/js.js",
    ]
  end

  def render(x, title:"Untitled", content:nil, body_class: "", message:{type:nil, message:nil}, css:[], js:[], js_ready: nil)
    x << head(x, title: title, css:css, body_class: body_class)
    x << nav(x)
    x.res.error.each{|e| x << alert(e[:type], e[:message]) }
    x << content
    x << app_modal(x)
    x << foot(x, js:js, js_ready: js_ready)
    x << piwik
    x << '</body></html>'
  end

  def page(x, title:nil, content:nil, message:{type:"alert", message: nil}, css:[], js:[], js_ready:nil)
    render(x, title:title, message: message, css: css, js: js, js_ready: js_ready, content:%(
      #{
      #App::Website::Html.chrome
      }
      <div class="container">
      <h1>#{h title}</h1>
      #{alert(message[:type], message[:message]) if message[:message]}
      #{content||page['content']}
      </div>
    ))
  end

  def head(x, title:"Untitled", description:"", author:"", css:[], body_class:"")
    %(
    <!DOCTYPE html>
    <!-- Copyright (c) #{Time.new.year} #{h Waxx/:site/:name} -->
    <meta charset="utf-8">
    <meta http-equiv="X-UA-Compatible" content="IE=edge">
    <title>#{h title}</title>
    <meta name="description" content="#{h description.to_s.gsub('"',"'")}">
    <meta name="author" content="#{h author}">
    <meta name="viewport" content="width=device-width,initial-scale=1,maximum-scale=1.0">
    <link rel="shortcut icon" type="image/x-icon" href="/lib/waxx/img/w.ico">
    <link rel="apple-touch-icon" sizes="200x200"   href="/lib/waxx/img/w.png">
    #{(standard_css + css).map{|f| %(<link href="#{f}" rel="stylesheet">) }.join}
    <body class="#{body_class}">
    )
  end

  def nav(x)
  %(
    <div class="navbar-wrapper">
      <div class="container">

        <nav class="navbar navbar-inverse navbar-static-top">
          <div class="container">
            <div class="navbar-header">
              <button type="button" class="navbar-toggle collapsed" data-toggle="collapse" data-target="#navbar" aria-expanded="false" aria-controls="navbar">
                <span class="sr-only">Toggle navigation</span>
                <span class="icon-bar"></span>
                <span class="icon-bar"></span>
                <span class="icon-bar"></span>
              </button>
              <a class="navbar-brand" href="#">#{h Waxx/:site/:name}</a>
            </div>
            <div id="navbar" class="navbar-collapse collapse">
              <ul class="nav navbar-nav">
                <li class="active"><a href="#">Home</a></li>
                <li><a href="#about">About</a></li>
                <li><a href="#contact">Contact</a></li>
                <li class="dropdown">
                  <a href="#" class="dropdown-toggle" data-toggle="dropdown" role="button" aria-haspopup="true" aria-expanded="false">Dropdown <span class="caret"></span></a>
                  <ul class="dropdown-menu">
                    <li><a href="#">Action</a></li>
                    <li><a href="#">Another action</a></li>
                    <li><a href="#">Something else here</a></li>
                    <li role="separator" class="divider"></li>
                    <li class="dropdown-header">Nav header</li>
                    <li><a href="#">Separated link</a></li>
                    <li><a href="#">One more separated link</a></li>
                  </ul>
                </li>
              </ul>
            </div>
          </div>
        </nav>

      </div>
    </div>
  )
  end

  def usr_menu(x)
    return "" #if not x.usr?
    cls = %w(usr).include?(x.app) ? "active" : "" 
    cls = "active" if x.app == 'letter' and x.act == 'list'
    %(<a class="#{cls}" href="/dashboard"><span class="glyphicon glyphicon-cog"></span></a>)
  end
  
  def admin(x, title:nil, content:nil, message:{type:"alert", message: nil}, css:[], js:[], js_ready:nil)
    render(x, title:title, content_class: "container", message: message, css: css, js: js, js_ready: js_ready, 
      content: %(
        <div style="background-color: white">
          <div class="container">
            #{admin_menu(x)}
            <div id="admin-panel">#{content}</div>
          </div>
        </div>
      )
    )
  end

  def admin_menu(x)
    re = [%(<!-- admin_menu -->\n<ul class="nav nav-tabs">)]
    re << [
      ["/admin","Admin","admin"],
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
  def alert(type="info", message="")
    signs = {success:"info", info:"info", warning:"warning", danger:"warning"}
    return "" if message.empty?
    %(<div class="alert alert-#{type}" role="alert"><strong>
    <span class="glyphicon glyphicon-#{signs[type.to_sym]}-sign"></span> #{message.h}</strong></div>)
  end

  def app_modal(x)
  %(
  <div style="display: none;" class="modal fade in" id="apps-modal" tabindex="-1" role="dialog" aria-hidden="true">
    <div class="modal-sm modal-dialog modal-dialog-top">
      <div class="modal-content">
        <div class="block block-themed block-transparent">
          <div class="block-header bg-primary-dark">
            <ul class="block-options">
              <li>
                <button data-dismiss="modal" type="button"><i class="si si-close"></i></button>
              </li>
            </ul>
            <h3 class="block-title"></h3>
          </div>
          <div class="block-content"></div>
        </div>
      </div>
    </div>
  </div>
  )
  end

  def foot(x, js:[], js_ready:"")
    %(
		<!-- FOOTER -->
		<footer class="container">
			<p class="pull-right"><a href="#">Back to top</a></p>
			<p>&copy; #{Time.new.year} #{h Waxx/:site/:name} &middot; <a href="#">Privacy</a> &middot; <a href="#">Terms</a></p>
			<p><a href="https://www.waxx.io/">Delivered by Waxx in #{((Time.new - x.req.start_time)*10000).to_i/10.0} ms</a>.</p>
    </footer>
    <!-- END Page Container -->
    #{(standard_js + js).map{|f| %(<script src="#{f}" type="text/javascript"></script>) }.join}
    <script type="text/javascript">
    $(document).ready(function(){
      #{js_ready}
    })
    </script>
    )
  end

  def piwik
    site_id = 9
    %(<!-- Piwik -->
    <script type="text/javascript">
      var _paq = _paq || []; _paq.push(['trackPageView']); _paq.push(['enableLinkTracking']);
      (function() {
        var u="https://stats.eparklabs.com/"; _paq.push(['setTrackerUrl', u+'piwik.php']); _paq.push(['setSiteId', #{site_id}]); var d=document, g=d.createElement('script'), s=d.getElementsByTagName('script')[0]; g.type='text/javascript'; g.async=true; g.defer=true; g.src=u+'piwik.js'; s.parentNode.insertBefore(g,s);
      })();                              
    </script>
    <noscript><p><img src="https://stats.eparklabs.com/piwik.php?idsite=#{site_id}" alt=""></p></noscript>
    )
  end

end
