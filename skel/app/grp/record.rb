module App::Grp::Record
  extend Waxx::View
  extend self

  @joins = {
    person:"LEFT JOIN person ON usr.person_id = person.person_id"
  }

  has(
    :id,
    :usr_name,
    "person_id:person.person_id",
    "first_name:person.first_name",
    "last_name:person.last_name",
    "company_id:person.company_id"
  )

  def save(x, id:0, data:{})
    if id.to_i == 0
      person = App::Person.post(x, {
        first_name: data['first_name'],
        last_name: data['last_name'],
        company_id: data['company_id']
      })
      App::Usr.create(x, {
        usr_name: data['usr_name'], 
        password: data['password'], 
        person_id: person['id']
      }, returning:"id")
    else
      App::Usr.set_password(x, id, data['password'])
      App::Usr.put(x, id, {usr_name: data['usr_name']})
      App::Person.put(x, id, {
        first_name: data['first_name'],
        last_name: data['last_name'],
        company_id: data['company_id']
      })
    end
    Html.post(x,{})
  end

  module Html
    extend Waxx::Html
    extend self

    def get(x, d, message:{})
      title = d.nil? ? "New User" : "#{d['first_name']} #{d['last_name']}"
      App::Html.admin(x,
        title: title,
        content: content(x, data: (d||{}), title: title)
      )
    end

    def post(x, data, message={})
      #App::Usr::List.view(x, meth: "get", message: {type: "success", message:"The user was updated successfully."})
      x.res.redirect "/usr"
    end

    def content(x, data:{}, title:"Untitled")
      %(
      <form action="" method="post">
        <div class="form-group">
          <label for="usr_name">First Name</label>
          <input type="text" id="first_name" name="first_name" class="form-control" value="#{h data['first_name']}">
        </div>
        <div class="form-group">
          <label for="usr_name">Last Name</label>
          <input type="text" id="last_name" name="last_name" class="form-control" value="#{h data['last_name']}">
        </div>
        <div class="form-group">
          <label for="company_id">Company</label>
          <select id="company_id" name="company_id" class="form-control">
          #{company_options(x, data)}
          </select>
        </div>
        <div class="form-group">
          <label for="usr_name">Email</label>
          <input type="text" id="usr_name" name="usr_name" class="form-control" value="#{h data['usr_name']}">
        </div>
        <div class="form-group">
          <label for="password">Password</label>
          <input type="password" id="password" name="password" class="form-control" value="">
        </div>
        <br>
        <button type="submit" class="btn btn-primary" name="btn" value="save">Save</button>
      </form>
      )
    end

    def company_options(x, data)
      App::Company.get(x, select:"id, name", order:"name").map{|r|
        selected = r['id'] == data['company_id'] ? "selected" : ""
        "<option value='#{r['id']}' #{selected}>#{h r['name']}</option>"
      }.join
    end

  end
end
