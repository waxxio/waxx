require 'securerandom'

# Trap ^C 
Signal.trap("INT") { 
  puts "\n\nInstallation terminated by INT (^C)\n"
  exit
}

# Trap `Kill `
Signal.trap("TERM") {
  puts "\n\nInstallation terminated by TERM\n"
  exit
}

# Command line init script to create a Waxx app
module Waxx::Init
  extend self

  # Defines the default YAML config file
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
  key: #{SecureRandom.base64(32)[0,32]}
  iv: #{SecureRandom.base64(16)[0,16]} 

cookie:
  user:
    name: wxu
    expires_after_login_mins: 1440
    expires_after_activity_mins: 480
    secure: true
  agent:
    name: wxa
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

  # Some nice ASCII Art to get people excited
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

  # Start the init process. Fired when `waxx init folder` is called
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
    puts "Does this look right? You can edit this YAML file later in #{opts/:sub_command}/opt/dev/config.yaml."
    print "Install? (y|n) [y]: "
    proceed = $stdin.gets.chomp
    if proceed == '' or (proceed =~ /[yY]/) == 0
      install_waxx(x, input, opts)
    else
      init(x, opts, input)
    end
  end

  # Make the Waxx::Root / app folder 
  def make_dir(x, name)
    puts ""
    if File.exist? name
      if not Dir.empty?(name)
        puts "Error. The directory '#{name}' already exists and is not empty."
        puts "I don't want to destroy anything. Bailing out."
        exit 4
      end
      puts "Installing into existing directory: #{name}"
      Dir.unlink name
    else
      puts "Make directory: #{name}"
    end
  end

  # Ask questions about the config
  def ask(x, input)
    get_site(x, input)
    get_key_iv(x, input)
    get_db(x, input)
    input
  end

  # Get config options about the site
  def get_site(x, input)
    puts ""
    puts "Website/App options:"
    print "  Name [#{input/:site/:name}]: "
    name = $stdin.gets.chomp
    print "  Support Email [#{input/:site/:support_email}]: "
    support_email = $stdin.gets.chomp
    print "  Liston on IP/Host [#{input/:server/:host}]: "
    host = $stdin.gets.chomp
    print "  Listen on Port [#{input/:server/:port}]: "
    port = $stdin.gets.chomp
    input['site']['name'] = name unless name == ''
    input['site']['support_email'] = support_email unless support_email == ''
    input['server']['host'] = host unless host == ''
    input['server']['port'] = port unless port == ''
    input['site']['url'] = "http://#{input['server']['host']}:#{input['server']['port']}"
    input
  end

  # Get config options about the db
  def get_db(x, input)
    default_db = "postgresql://#{`whoami`.chomp}@localhost/#{`whoami`.chomp}"
    puts ""
    puts "Enter your database connection string (type://user:pass@host:port/db)"
    puts "Types include: postgresql, mysql2, sqlite3, mongodb"
    puts "You can edit or add more database connections by editing opt/dev/config.yaml"
    puts "Enter 'none' if you do not want to connect to a database now"
    puts "[#{input['databases']['app'] || default_db}] "
    print "  db: "
    db = $stdin.gets.chomp
    if db.downcase == "none"
      input['databases'] = {}
    else
      input['databases']['app'] = db == '' ? (input['databases']['app'] || default_db) : db
      puts "Create the standard waxx table? (The waxx table is used for migration management.)"
      puts "The databse must already exist and the user must have create table privileges."
      print "  Create waxx table (y|n) [y]:"
      initdb = $stdin.gets.chomp
      initdb = initdb == '' or not (initdb =~ /[Yy]/).nil?
      input['init']['db'] = initdb
    end
    input
  end

  # Get config options about the encryption
  def get_key_iv(x, input)
    puts ""
    puts "The AES key and initiation vector for encryption."
    puts "The default was generated with SecureRandom.base64()."
    puts "Accept the default or enter 48 (or more) random characters."
    puts "Can not start with an ampersand: &"
    puts "See https://www.grc.com/passwords.htm for inspiration."
    puts "[#{input['encryption']['key']}#{input['encryption']['iv']}] "
    print "  Random string: "
    random = $stdin.gets.chomp
    if random.size >= 48
      input['encryption']['key'] = random[0,32]
      input['encryption']['iv'] = random[33,16]
    end
    input
  end
   
  # Install Waxx in the target folder. Copy skel and update the config file
  def install_waxx(x, input, opts)
    skel_folder = "#{File.dirname(__FILE__)}/../../skel/"
    install_folder = opts/:sub_command
    puts ""
    puts "Copying files from #{skel_folder} to #{install_folder}"
    FileUtils.cp_r(skel_folder, install_folder, verbose: false)
    if input/:init/:db
      puts ""
      puts "Setup Database"
      create_waxx_table(x, input)
    end
    if not (input/:databases).empty?
      # Require the correct db lib in app/app.rb
      db_libs = {pg: 'pg', postgresql: 'pg', mysql: 'mysql2', mysql2: 'mysql2', sqlite: 'sqlite3', sqlite3: 'sqlite3', mongo: 'mongodb', mongodb: 'mongodb'}
      db_lib = db_libs[(input/:databases/:app).split(":").first.to_sym]
      puts "Requiring lib '#{db_lib}' in app/app.rb"
      app_rb = File.read("#{install_folder}/app/app.rb")
      File.open("#{install_folder}/app/app.rb","w"){|f|
        f.puts app_rb.sub("# require '#{db_lib}'","require '#{db_lib}'") 
      }
    end
    puts ""
    puts "Installing dev config"
    input.delete "init"
    File.open("#{install_folder}/opt/dev/config.yaml","w"){|f| f << input.to_yaml}
    puts ""
    puts "Waxx installed successfully."
    puts "cd into #{install_folder} and run `waxx on` to get your waxx on"
  end

  def create_waxx_table(x, input)
    # Require the db lib
    case (input/:databases/:app).split(":").first.downcase
      when 'postgresql'
        require 'pg'
      when 'mysql2'
        require 'mysql2'
      when 'sqlite3'
        require 'sqlite3'
    end
    create_sql = %(
      CREATE TABLE waxx (
        name character varying(254) NOT NULL PRIMARY KEY,
        value character varying(254) NOT NULL,
        CONSTRAINT waxx_uniq UNIQUE(name)
      )
    )
    insert_sql = %(INSERT INTO waxx (name, value) VALUES ('db.app.migration.last', '0'))
    puts "  Connecting to: #{input/:databases/:app}"
    begin
      db = Waxx::Database.connect(input/:databases/:app)
      db.exec(create_sql)
      db.exec(insert_sql)
      puts "  Waxx table created successfully."
    rescue => e
      puts %(
        \nERROR: Could not create waxx table. Please create manually:
        \n#{create_sql}
        \n#{insert_sql}
        \nError Detail: #{e}
      )
    end
  end
end
