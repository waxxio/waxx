module Waxx::Generate
  extend self

  def gen(x, scope, app, act=nil, type='record')
    folder = app_folder(app)
    columns = Waxx::Pg.columns_for(x, app)
    if %w(app object obj).include? scope.to_s
      obj(folder, app, columns)
    end
    if %w(view).include? scope.to_s
      view(folder, app, act, type, columns)
    end
    if %w(app).include? scope.to_s
      view(folder, app, 'list', 'list', columns)
      view(folder, app, 'record', 'record', columns)
    end
  end

  def app_folder(app)
    folder = "app/#{app.to_s.strip.gsub("_","/")}"
    begin
      FileUtils.mkdir_p folder
      puts "Created folder #{folder}"
    rescue => e
      puts "Could not make app folder. Skipping."
    end
    folder
  end

  def obj(folder, app, columns)
    file = "#{folder}/#{app.strip}.rb"
    if File.exist? file
      puts "#{file} already exists. Skipping."
      return
    end
    # Build the object file
    re = [
      "module App::#{Waxx::Util.camel_case(app.strip)}",
      "  extend Waxx::Pg",
      "  extend self",
      "",
      "  has(",
    ]
    columns.each{|rec|
      primary = rec['pkey'] ? ", pkey: true" : ""
      re << %(    #{rec['column_name']}: {type: '#{rec['data_type'].split(' ').first  }'#{primary}},) 
    }
    re << [
      "  )",
      "",
      "  runs(",
      "    default: 'list',",
      "    list: {",
      "      desc: 'List #{app} records',",
      "      acl: %w(user),",
      "      get: -> (x) {",
      "        #{app}s = List.get(x)",
      "        List.render(x, #{app}s)",
      "      }",
      "    },",
      "    record: {",
      "      desc: 'CRUD #{app} records',",
      "      acl: %w(user),",
      "      get: -> (x, id=0) {",
      "        #{app} = id.to_i == 0 ? {id: 0} : Record.by_id(x, id)",
      "        Record.render(x, #{app})",
      "      },",
      "      post: -> (x, id=0) {",
      "        #{app} = id.to_i == 0 ? Record.post(x, x.req.post) : Record.put(x, id, x.req.post)",
      "        return x << #{app}.to_json if x.ext == 'json'",
      "        x.res.redirect('/#{app}/list')",
      "      },",
      "      put: -> (x, id) {",
      "        #{app} = Record.put(x, id, x.req.post)",
      "        return x << #{app}.to_json if x.ext == 'json'",
      "        x.res.redirect('/#{app}/list')",
      "      },",
      "      delete: -> (x, id) {",
      "        Record.delete(x, id)",
      "        return x << {ok: true, id: id}.to_json if x.ext == 'json'",
      "        x.res.redirect('/#{app}/list')",
      "      },",
      "    },",
      "  )",
      "",
      "end",
      "",
    ]
    File.open(file, 'w'){|f| f.puts re.join("\n") }
    puts "Created object file: #{file}"
  end

  def view(folder, app, act, type, columns)
    file = "#{folder}/#{act.strip}.rb"
    if File.exist? file
      puts "#{file} already exists. Skipping."
      return
    end
    # Build the object file
    re = [
      "module App::#{Waxx::Util.camel_case(app.strip)}::#{Waxx::Util.camel_case(act.strip)}",
      "  extend Waxx::View",
      "  extend self",
      "",
      "  # Specify what formats this view will render automatically",
      "  as :json",
      "",
      "  # Specify what fields are on this view (only these fields will be rendered and updated)",
      "  has(",
      columns.map{|rec| %(    :#{rec['column_name']},) },
      "  )",
      "",
    ]
    if type.to_s == 'list'
      re << [
      "  # Add the fields that can be matched with get(x, args: x.req.get)",
      "  match_in(:#{columns[0]['column_name']})",
      "  # Add the fields that can be searched using the 'q' parameter in args",
      "  search_in(:#{columns[1]['column_name']})",
      "",
      ]
    end
    re << [
      "  # This is the HTML view. Delete this module if you are not rendering HTML.",
      "  module Html",
      "    extend Waxx::Html",
      "    extend self",
      "",
      "    def get(x, #{type == 'record' ? app : 'data'}, message: {})",
      "      title = #{type == 'record' ? "#{app}/:id == 0 ? 'New #{app.capitalize}' : #{app}/:name" : "'#{app.capitalize}s'"}",
      "      App::Html.page(x, title: title, content: #{type}(x, #{type == 'record' ? app: 'data'}), message: message)",
      "    end",
      "",
    ]
    if type.to_s == 'record'
      re << [
      "    def record(x, #{app})",
      "    %(",
      %(      <form action="/#{app}/#{act}/#{'#{'}#{app}/:id}" method="post">),
      columns.map{|c|
        next if c['pkey']
        %(
        <label for="#{c/:column_name}" class="fssr mt-m">#{c['column_name'].title_case}</label>
        <input id="#{c['column_name']}" name="#{c['column_name']}" class="form" value="#{'#{h '}#{app}/:#{c['column_name']}}">)
      },
      %(        <div class="df g-s">),
      %(          <button type="submit" class="btn btn-primary">Save</button>),
      %(          <a href="/#{app}/list" class="btn">Cancel</a>),
      %(        </div>),
      %(      </form>),
      "    )",
      "    end",
      ]
    else
      re << [
      "    def list(x, data)",
      "    %(",
      %(      <a href="/#{app}/record/0" class="fr btn btn-primary">New #{app.title_case}</a>),
      %(      <table class="mt-m data">),
      %(        <thead>),
      %(          <tr>),
      columns.map{|c| %(          <th>#{c['column_name'].title_case}</th>) },
      %(          </tr>),
      %(        </thead>),
      %(        <tbody>),
      '          #{data.map{|rec|',
      '            %(',
      '            <tr>',
      columns.map{|c| %(              <td>#{'#{h rec/:'}#{c['column_name']}}</td>) },
      %(              <td><a href="/#{app}/record/#{'#{'}rec/:id}">edit</a></td>),
      '            </tr>',
      '            )',
      '          }.join("\n")}',
      %(        </tbody>),
      %(      </table>),
      "    )",
      "    end",
      ]
    end
    re << "  end"
    re << "end"
    # Write the view file
    File.open(file, 'w'){|f| f.puts re.join("\n") }
    # Require the view file from the object file
    File.open("#{folder}/#{app}.rb", 'a'){|f| f.puts %(require_relative "#{act}") }
    puts "Created view file: #{file}"
  end

end
