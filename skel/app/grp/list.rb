module App::Grp::List
  extend Waxx::View
  extend self

  @joins = {
    person:"LEFT JOIN person ON usr.person_id = person.person_id",
    company:"LEFT JOIN company ON person.company_id = company.company_id"
  }

  has(
    :id,
    :usr_name,
    :last_login_date,
    :failed_login_count,
    "person_id: person.person_id",
    "person.first_name",
    "person.last_name",
    "company_name: company.company_name"
  )

  module Html
    extend Waxx::Html
    extend self

    def get(x, d, message:{})
      title = "People"
      App::Html.admin(x,
        title: title,
        content: content(x, data: (d||{}), title: title),
        js_ready: %(
          $('#usrs tr').click(function(ev){
            location=$(ev.target.parentElement).attr('href');
          })
        )
      )
    end

    def content(x, data:{}, title:"Untitled")
      re = [%(<table id="usrs" class="table table-hover">
      <tr><th>ID</th><th>Name</th><th>Company</th><th>User Name</th><th>Last Login</th><th>Failed Logins</th></tr>
      )]
      re << data.map{|u|
        %(<tr href="/usr/record/#{u/:id}" style="cursor:pointer;"><td>#{u/:id}</td>
        <td>#{h u/:first_name} #{h u/:last_name}</td>
        <td>#{h u/:company_name}</td>
        <td>#{u/:usr_name}</td>
        <td>#{u['last_login_date'].nil? ? "" : "#{u['last_login_date'].f("%d-%b-%Y @%H:%M")} from #{u/:last_login_host}"}</td>
        <td>#{u/:failed_login_count}</td>
        </tr>)
      }
      re << %(</table><a href="/usr/record/0" class="btn btn-success"><span class="glyphicon glyphicon-plus"></span> Add User</a>)
      re.join
    end

  end
end
