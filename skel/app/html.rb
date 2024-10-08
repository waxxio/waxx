module App::Html
  extend Waxx::Html
  extend self
      
  def standard_css
    %w(
      https://cdn.tersecss.com/css/terse.min.css
      https://cdn.tersecss.com/css/size.min.css
      https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.6.0/css/all.min.css
    )
  end

  def standard_js
    %w(
      /app/js.js
    )
  end

  def render(x, title:"Untitled", content:nil, body_class: "", message:{type:nil, message:nil}, css:[], js:[], js_ready: nil)
    x << head(x, title: title, css:css, body_class: body_class)
    x << nav(x)
    x.res.error.each{|e| x << alert(e[:type], e[:message]) }
    x << content
    x << foot(x)
    x << script(x, js:js, js_ready: js_ready)
    x << '</body></html>'
  end

  def page(x, title:nil, content:nil, message:{type:"alert", message: nil}, css:[], js:[], js_ready:nil)
    render(x, title: title, message: message, css: css, js: js, js_ready: js_ready, content: %(
      <div class="p-l">
      <h1>#{h title}</h1>
      #{alert(message[:type], message[:message]) if message[:message]}
      #{content}
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
    <meta name="viewport" content="width=device-width,initial-scale=1">
    <link rel="shortcut icon" type="image/x-icon" href="favicon.ico">
    #{(standard_css + css).map{|f| %(<link href="#{f}" rel="stylesheet">) }.join}
    <body class="#{body_class}">
    )
  end

  def nav(x)
    %(
    <nav class="df g-m p-m">
      <a href="/">Home</a>
      <a href="/about">About</a>
    </nav>
    )
  end

  def usr_menu(x)
    if x.usr?
      %(
      <a href="/usr/profile"><i class="fa-light fa-user"></i> #{h x.usr['un']}</a>
      <a href="/usr/signout"><i class="fa-light fa-exit"></i> #{h x.usr['un']}</a>
      )
    else
      %(
      <a href="/usr/signup">Sign up</a>
      <a href="/usr/signin">Sign in</a>
      )
    end
  end
  
  # Type can be: success info warning danger
  def alert(type="info", message="")
    return "" if message.empty?
    signs = {success: "info", info: "info", warning: "warning", danger: "warning"}
    %(
    <div class="alert alert-#{type}" role="alert">
      <i class="fa-light fa-#{signs[type.to_sym]}"></i> #{message.h}
    </div>
    )
  end

  def foot(x)
    %(
		<footer class="p-l">
			<p class="pull-right"><a href="#">Back to top</a></p>
			<p>&copy; #{Time.new.year} #{h Waxx/:site/:name} &middot; <a href="/about/privacy">Privacy</a> &middot; <a href="/about/terms">Terms</a></p>
			<p><a href="https://www.waxx.io/">Delivered by Waxx in #{'%.1f' % ((Time.new - x.req.start_time) * 1000)} ms</a>.</p>
    </footer>
    )
  end

  def script(x, js:[], js_ready:"")
    %(
    #{(standard_js + js).map{|f| %(<script src="#{f}"></script>) }.join}
    <script>document.addEventListener('DOMContentLoaded', () => { #{js_ready} });</script>
    )
  end

end
