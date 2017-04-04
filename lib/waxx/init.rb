# Trap ^C 
Signal.trap("INT") { 
  puts "\n\nInstalation terminated by INT (^C)\n"
  exit
}

# Trap `Kill `
Signal.trap("TERM") {
  puts "\n\nInstalation terminated by TERM\n"
  exit
}

module Waxx::Init
  extend self

  def default_input(x, opts)
  %(---
server:
  host: localhost
  port: 7777
  processes: 1
  min_threads: 4
  max_threads: 4
  log_dir: log
  pid_dir: tmp/pids

site:
  name: #{`whoami`.chomp.capitalize}'s Website
  support_email: #{`whoami`.chomp}@#{`hostname`.chomp}
  url: http://localhost:7777

encryption:
  cipher: AES-256-CBC
  key: 
  iv:  

cookie:
  user:
    name: u
    expires_after_login_mins: 1440
    expires_after_activity_mins: 480
    secure: true
  agent:
    name: a
    expires_years: 30
    secure: true

debug:
  level: 9
  on_screen: true
  send_email: false
  email: #{`whoami`.chomp}@#{`hostname`.chomp}
  auto_reload_code: true

databases:
  app: 

default:
  app: website
  act: index
  ext: html

file:
  serve: true
  path: public

init:
  website: true
  html: true
  )
  end

  def ascii_art
    # http://www.patorjk.com/software/taag/
    %(
`8.`888b                 ,8' .8.          `8.`8888.      ,8' `8.`8888.      ,8' 
 `8.`888b               ,8' .888.          `8.`8888.    ,8'   `8.`8888.    ,8'  
  `8.`888b             ,8' :88888.          `8.`8888.  ,8'     `8.`8888.  ,8'   
   `8.`888b     .b    ,8' . `88888.          `8.`8888.,8'       `8.`8888.,8'    
    `8.`888b    88b  ,8' .8. `88888.          `8.`88888'         `8.`88888'     
     `8.`888b .`888b,8' .8`8. `88888.         .88.`8888.         .88.`8888.     
      `8.`888b8.`8888' .8' `8. `88888.       .8'`8.`8888.       .8'`8.`8888.    
       `8.`888`8.`88' .8'   `8. `88888.     .8'  `8.`8888.     .8'  `8.`8888.   
        `8.`8' `8,`' .888888888. `88888.   .8'    `8.`8888.   .8'    `8.`8888.  
         `8.`   `8' .8'       `8. `88888. .8'      `8.`8888. .8'      `8.`8888.

                                Version #{Waxx::Version}
    )
  end

  def standard_sql
    {
      app_log: %(),
      email: %(),
      grp: %(),
      usr: %(),
      usr_grp: %(),
      waxx: %(),
    }
  end

  def website_sql
    {
      website: %(),
      website_host: %(),
      website_page: %(),
      website_page_tag: %()
    }
  end

  def init(x, opts, input=nil)
    puts ""
    puts ascii_art
    puts ""
    # Set defaults
    input ||= YAML.load(default_input(x, opts))
    make_dir(x, opts/:sub_command)
    # Ask a few questions
    input = ask(x, input)
    puts ""
    puts "Here is your config..."
    puts ""
    puts input.to_yaml
    puts ""
    puts ""
    puts "Does this look right? You can edit this YAML file in #{opts/:sub_command}/opt/dev/config.yaml."
    print "Install? (y|n) [y]: "
    proceed = $stdin.gets.chomp
    if proceed == '' or (proceed =~ /[yY]/) == 0
      install_waxx(x, input, opts)
    else
      init(x, opts, input)
    end
  end

  def make_dir(x, name)
    puts ""
    if File.exist? name
      if not Dir.empty?(name)
        puts "Error. The directory '#{name}' already exists and is not empty."
        puts "I don't want to destroy anything. Bailing out."
        exit 4
      end
      puts "Installing into existing directory: #{name}"
    else
      puts "Make directory: #{name}"
      Dir.mkdir(name)
    end
  end

  def ask(x, input)
    get_site(x, input)
    get_server(x, input)
    get_website(x, input)
    get_db(x, input)
    get_key_iv(x, input)
    input
  end

  def get_site(x, input)
    puts ""
    puts "Website/App options:"
    print "  Name [#{input/:site/:name}]: "
    name = $stdin.gets.chomp
    print "  Support Email [#{input/:site/:support_email}]: "
    support_email = $stdin.gets.chomp
    print "  URL (how users access the site) [#{input/:site/:url}]: "
    url = $stdin.gets.chomp
    input['site']['name'] = name unless name == ''
    input['site']['support_email'] = support_email unless support_email == ''
    input['site']['url'] = url unless url == ''
    input
  end

  def get_server(x, input)
    puts ""
    puts "Server options:"
    print "  Liston on IP/Host [#{input/:server/:host}]: "
    host = $stdin.gets.chomp
    print "  Port [#{input/:server/:port}]: "
    port = $stdin.gets.chomp
    input['server']['host'] = host unless host == ''
    input['server']['port'] = port unless port == ''
    input
  end

  def get_website(x, input)
    print "\nInstall the website app? (y|n) [#{input['init']['website'] ? 'y' : 'n'}]: " 
    website = $stdin.gets.chomp
    website = true if website == '' or not (website =~ /[Yy]/).nil?
    if website
      html = true
    else
      print "\nSupport HTML output? (y|n) [#{input['init']['html'] ? 'y' : 'n'}]: "
      html = ($stdin.gets.chomp =~ /[Yy]/) == 0
      html = true if html == '' or not (html =~ /[Yy]/).nil?
    end
    input['init']['website'] =  website
    input['init']['html'] =  html
    input
  end

  def get_db(x, input)
    default_db = "postgresql://#{`whoami`.chomp}@localhost/#{`whoami`.chomp}"
    puts ""
    puts "Enter your database connection string (type://user:pass@host:port/db)"
    puts "[#{input['databases']['app'] || default_db}] "
    print "  db: "
    db = $stdin.gets.chomp
    input['databases']['app'] = db == '' ? (input['databases']['app'] || default_db) : db
    puts "Create standard Waxx tables?"
    puts "These include: #{standard_sql.keys.join(", ")}."
    print "Create tables (y|n) [y]"
    initdb = $stdin.gets.chomp
    initdb = initdb == '' or not (initdb =~ /[Yy]/).nil?
    input['init']['db'] = initdb
    input
  end

  def set_random_key_iv(input)
    OpenSSL::Random.seed(ENV.inspect)
    random = Base64.encode64(OpenSSL::Random.pseudo_bytes(48))
    input['encryption']['key'] = random[0,32]
    input['encryption']['iv'] = random[33,16]
    input
  end

  def get_key_iv(x, input)
    if input['encryption']['key'].to_s.size != 32
      set_random_key_iv(input)
    end
    puts "\nThe AES key and initiation vector for encryption."
    puts "The default is a pseudo random generated with OpenSSL."
    puts "Enter or paste 48 (or more) random characters."
    puts "See https://www.grc.com/passwords.htm for inspriation."
    puts "[#{input['encryption']['key']}#{input['encryption']['iv']}] "
    print "  Random string: "
    random = $stdin.gets.chomp
    if random.size >= 48
      input['encryption']['key'] = random[0,32]
      input['encryption']['iv'] = random[33,16]
    end
    input
  end

  def install_waxx(x, input, opts)
    skel_folder = "#{File.dirname(__FILE__)}/../../skel/"
    puts ""
    puts "Copying files from #{skel_folder} to #{opts/:sub_command}/"
    puts `rsync -av #{skel_folder} #{opts/:sub_command}/`
    puts "Installing dev config"
    input.delete "init"
    File.open("#{opts/:sub_command}/opt/dev/config.yaml","w"){|f| f << input.to_yaml}
    puts ""
    puts "Waxx installed successfully."
    puts "cd into #{opts/:sub_command} and run `waxx on` to get your waxx on"
  end

end
