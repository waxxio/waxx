# Waxx Copyright (c) 2016 ePark labs Inc. & Daniel J. Fitzpatrick <dan@eparklabs.com> All rights reserved.
# Released under the Apache Version 2 License. See LICENSE.txt.

module Waxx::Http
  extend self

  def content_types
    ContentTypes
  end

  def ctype(t, default="application/octet-stream")
    ContentTypes[t.to_sym] || default
  end

  def time(t=Time.new.utc)
    t.strftime('%a, %d %b %Y %H:%M:%S UTC')
  end

  def escape(str)
    str.to_s.gsub(/([^a-zA-Z0-9_.-]+)/) do |m|
      '%' + m.unpack('H2' * m.bytesize).join('%').upcase
    end
  end
  alias qs escape

  def unescape(str)
    str.to_s.tr('+', ' ').gsub(/((?:%[0-9a-fA-F]{2})+)/) do |m|
      [m.delete('%')].pack('H*')
    end
  end

  def parse_head(io)
    env = {}
    head = ""
    while(e = io.gets)
      break if e.strip == ""
      head << e
      n, v = e.split(":", 2)
      env[n] = v.strip
    end
    [env, head]
  end

  def query_string_to_hash(str)
    return {} if str.nil? or str.strip == ""
    #Hash[*str.split(/[;&]/).map{|da| Waxx::Http.unescape(da.strip).split("=",2)}.flatten]
    re = {}
    str.strip.split(/[;&]/).each{|nv|
      n, v = nv.split("=",2)
      if n =~ /\[\]$/
        n = n.sub(/\[\]$/,"")
        re[n] ||= []
        re[n] << unescape(v)
      else
        re[n] = unescape(v)
      end
    }
    re
  end

  def parse_multipart(env, data)
    boundary = env['Content-Type'].match(/boundary=(.*)$/)[1]
    parts = data.split("--"+boundary+"\r\n")
    post = {}
    parts.each{|part|
      next if part.strip == ""
      begin
        head, body = part.split("\r\n\r\n",2)
        headers = Hash[*(head.split("\r\n").map{|hp| hp.split(":",2).map{|i| i.strip}}.flatten)]
        cd = Hash[*("_=#{headers['Content-Disposition']}".split(";").map{|da| da.strip.gsub('"',"").split("=",2)}.flatten)]
        if cd['filename']
          post[cd['name']] = {
            filename: cd['filename'],
            data: body.sub(/\r\n--#{boundary}--\r\n$/,"").sub(/\r\n$/,""),
            content_type: headers['Content-Type'],
            headers: headers
          }
        else
          post[cd['name']] = body.sub(/\r\n--#{boundary}--\r\n$/,"").sub(/\r\n$/,"")
        end
      rescue => e
        debug "Error parse_multipart: #{e}"
        post["Error in parse_multipart (uid-#{rand})"] = e
      end
    }
    post
  end

  def parse_cookie(str)
    Waxx.debug "parse_cookie"
    re = {}
    return re if str.nil? or str == ""
    str.split(/[;,]\s?/).each do |pairs|
      name, values = pairs.split('=',2)
      next unless name and values
      name = unescape(name)
      vals = values.split('&').collect{|v| unescape(v) }
      if re.has_key?(name)
        debug "re has key"
        if Array === re[name]
          re[name].push vals
        else
          re[name] = [re[name], vals]
        end
      else
        re[name] = vals
      end
      re[name].flatten!
    end
    re.freeze
    re
  end

  def parse_data(env, meth, io, head)
    Waxx.debug "parse_data"
    if %w(PUT POST PATCH).include? meth
      data = io.read(env['Content-Length'].to_i)
      debug "data.size: #{data.size} #{env['Content-Type']}"
      case env['Content-Type']
        when /x-www-form-urlencoded/
          post = query_string_to_hash(data).freeze
        when /multipart/
          post = parse_multipart(env, data).freeze
        when /json/
          post = (JSON.parse(data)).freeze
        else
          post = data.freeze
      end
    else
      post = {}.freeze
      data = nil
    end
    [post, data]
  end

  Status = {
    "200"=>"OK",
    "206"=>"Partial Content",
    "300"=>"Multiple Choices",
    "301"=>"Moved Permanently",
    "302"=>"Found",
    "304"=>"Not Modified",
    "400"=>"Bad Request",
    "401"=>"Authorization Required",
    "403"=>"Forbidden",
    "404"=>"Not Found",
    "405"=>"Method Not Allowed",
    "406"=>"Not Acceptable",
    "411"=>"Length Required",
    "412"=>"Precondition Failed",
    "500"=>"Internal Server Error",
    "501"=>"Method Not Implemented",
    "502"=>"Bad Gateway",
    "506"=>"Variant Also Negotiates"
  }

  ContentTypes = {
    css:     "text/css; charset=utf-8",
    csv:     "text/csv; charset=utf-8",
    htm:     "text/html; charset=utf-8",
    html:    "text/html; charset=utf-8",
    jpg:     "image/jpeg",
    js:      "application/javascript; charset=utf-8",
    json:    "application/json; charset=utf-8",
    tab:     "text/tab-separated-values; charset=utf-8",
    txt:     "text/plain; charset=utf-8",
    xml:     "text/xml",                              
    gif:     "image/gif",                             
    jpeg:    "image/jpeg",                            
    atom:    "application/atom+xml",                  
    rss:     "application/rss+xml",                   
             
    mml:     "text/mathml",                           
    jad:     "text/vnd.sun.j2me.app-descriptor",      
    wml:     "text/vnd.wap.wml",                      
    htc:     "text/x-component",                      
             
    png:     "image/png",                             
    tif:     "image/tiff",
    tiff:    "image/tiff",                            
    wbmp:    "image/vnd.wap.wbmp",                    
    ico:     "image/x-icon",                          
    jng:     "image/x-jng",                           
    bmp:     "image/x-ms-bmp",                        
    svg:     "image/svg+xml",
    svgz:    "image/svg+xml",                         
    webp:    "image/webp",                            
             
    woff:    "application/font-woff",                 
    jar:     "application/java-archive",
    war:     "application/java-archive",
    ear:     "application/java-archive",              
    hqx:     "application/mac-binhex40",              
    doc:     "application/msword",                    
    pdf:     "application/pdf",                       
    ps:      "application/postscript",
    eps:     "application/postscript",
    ai:      "application/postscript",                
    rtf:     "application/rtf",                       
    m3u8:    "application/vnd.apple.mpegurl",         
    xls:     "application/vnd.ms-excel",              
    eot:     "application/vnd.ms-fontobject",         
    ppt:     "application/vnd.ms-powerpoint",         
    wmlc:    "application/vnd.wap.wmlc",              
    kml:     "application/vnd.google-earth.kml+xml",  
    kmz:     "application/vnd.google-earth.kmz",      
    cco:     "application/x-cocoa",                   
    jardiff: "application/x-java-archive-diff",       
    jnlp:    "application/x-java-jnlp-file",          
    run:     "application/x-makeself",                
    pl:      "application/x-perl",
    pm:      "application/x-perl",                    
    prc:     "application/x-pilot",
    pdb:     "application/x-pilot",                   
    rar:     "application/x-rar-compressed",          
    rpm:     "application/x-redhat-package-manager",  
    sea:     "application/x-sea",                     
    swf:     "application/x-shockwave-flash",         
    sit:     "application/x-stuffit",                 
    tcl:     "application/x-tcl",
    tk:      "application/x-tcl",                     
    der:     "application/x-x509-ca-cert",
    pem:     "application/x-x509-ca-cert",
    crt:     "application/x-x509-ca-cert",            
    xpi:     "application/x-xpinstall",               
    xhtml:   "application/xhtml+xml",                 
    xspf:    "application/xspf+xml",                  
    zip:     "application/zip",                       
             
    bin:     "application/octet-stream",
    exe:     "application/octet-stream",
    dll:     "application/octet-stream",             
    deb:     "application/octet-stream",             
    dmg:     "application/octet-stream",             
    iso:     "application/octet-stream",
    img:     "application/octet-stream",             
    msi:     "application/octet-stream",
    msp:     "application/octet-stream",
    msm:     "application/octet-stream",             
             
    docx:    "application/vnd.openxmlformats-officedocument.wordprocessingml.document",   
    xlsx:    "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet",          
    pptx:    "application/vnd.openxmlformats-officedocument.presentationml.presentation",  
    
    mid:     "audio/midi",
    midi:    "audio/midi",
    kar:     "audio/midi",                           
    mp3:     "audio/mpeg",                           
    ogg:     "audio/ogg",                            
    m4a:     "audio/x-m4a",                          
    ra:      "audio/x-realaudio",                    
             
    ts:      "video/mp2t",                           
    mp4:     "video/mp4",                            
    mpeg:    "video/mpeg",
    mpg:     "video/mpeg",                           
    mov:     "video/quicktime",                      
    webm:    "video/webm",                           
    flv:     "video/x-flv",                          
    m4v:     "video/x-m4v",                          
    mng:     "video/x-mng",                          
    asx:     "video/x-ms-asf",
    asf:     "video/x-ms-asf",                       
    wmv:     "video/x-ms-wmv",                       
    avi:     "video/x-msvideo",                      

  }
end
