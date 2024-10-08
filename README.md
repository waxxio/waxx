# Waxx - Web Application X(x)

The Waxx Framework is a high perfomance, functional-inspired (but not truly functional), web application development environment written in Ruby and inspired by Go and Haskel.

## Goals

1. High Perfomance (similar to Node and Go)
2. Easy to grok
3. Fast to develop
4. Efficient to maintain
5. Fast and easy to deploy

## Target Users

The Waxx Framework was developed to build CRUD applications and REST and RPC services. It scales very well on multi-core machines and is suitable for very large deployments.

## Who's Behind This

Waxx was developed by Dan Fitzpatrick at [ePark Labs](https://www.eparklabs.com/).

## Hello World

_app/hello/hello.rb:_

```ruby
module App::Hello
  extend Waxx::Object

  runs(
    default: "world",
    world: {
      desc: "This says Hello World",
      get: -> (x) {
        x << "Hello World!"
      }
    }
  )
end
```

URL: example.com/hello or example.com/hello/world

returns "Hello World"

NOTE: This is not the way you build a normal app. Just here because everyone wants to see a Hello World example.

## Introduction to Waxx

### Normal Install

```bash
sudo gem install waxx
waxx init site
cd site
waxx on
```

### Secure Install

The Waxx gem is cryptographically signed to be sure the gem you install hasn't been tampered with.
Because of this you need to add the public key to your list of trusted gem certs.
Follow these direction. (You only need step one the first time you install the gem.)

```bash
sudo gem cert --add <(curl -s https://www.waxx.io/waxx-gem-public-key.pem)
sudo gem install waxx -P HighSecurity
waxx init site
cd site
waxx on
```

Visit [http://localhost:7777/](http://localhost:7777/). If you want a different port, edit `opt/dev/config.yaml` first.
Then run `waxx buff` (waxx off && waxx on) or if you prefer `waxx restart`

See [Install Waxx](https://www.waxx.io/doc/install) for complete details.

### High Performance
Waxx is multi-threaded queue-based system.
You specify the number of threads in the config file.
Each thread is prespawned and each thread makes it's own database connection.
Requests are received and put into a FIFO request queue.
The threads work through the queue.
Each request, including session management, a database query, access control, and rendering in HTML or JSON is approximately 1 ms (on a modern laptop or server).
With additional libraries, Waxx also easily generates XML, XLSX, CSV, PDF, etc.

### Easy to Grok
Waxx has no classes.
It is Module-based and the Modules have methods (functions).
Each method within a Module is given parameters and the method runs in isolation.
There are no instance variables and no global variables.
Consequently, it is very easy to understand what any method does and it is very easy to test methods.
You can call any method in the whole system from the console using `waxx console`.
Passing in the same variables to a function will always return the same result.
Waxx does have `x.res.out` variable, which is appended to with `x << "text"`, that is passed into each method and any method can append to the response body or set response headers.
So it is not truly functional because this is a side effect.
My opinion is that when you are building a response, then copying the response on every method is a waste of resources.
So it does have this side effect by design.

#### Waxx Terminology

- Object: A database table or database object or a container for some specific functionality
- Object `has` fields (an array of Hashes). A field is both a database field/column/attribute and a UI control (for HTML apps)
- Field `is` (represents) a single object (INNER JOIN) or many related objects (LEFT JOIN)
- Object `runs` a URL path - business logic (normally get from or post to a view)
- View: Like a DB view -- fields from one or more tables/objects
- Html, Json, Xlsx, Tab, Csv, Pdf, etc.: How to render the view
- x is a variable that is passed to nearly all methods and contains the request (`x.req` contains: get and post vars, request cookies, and environment), response (`x.res` contains the status, response cookies, headers, and content body), user session (x.usr), and user agent (x.ua) cookies

#### The "x" Variable

- `x.req` contains: get and post vars, request cookies, environment, and some helper methods
  - `x.req.get` is a hash of vars passed in the query string
  - `x.req.post` is a hash of vars passed in the body of the request
  - `x.req.env` is a hash of the environment
  - `x.req['header-name']` is a shortcut to incoming headers / environment vars - always lower-case
  - `x['param_name']` and `x/:param_name` are shortcuts to get and post vars (post vars override get vars)
- `x.res` contains the status, response cookies, headers, and content body
  - `x << "some text"` appends to the body
  - `x.res['header-name'] = "value"` to set a response header
  - `x.status = 404` set the status. Defaults to 200.
- `x.usr` is the session cookie hash (set expiration params in opt/{env}/config.yaml)
  - `x.usr['name'] = 'Joe'` will set the name variable in the `x.usr` variable accross requests.
- `x.ua` is the client (user agent) cookie hash (set expiration params in opt/{env}/config.yaml). This is normally a long-lived cookie to store login name, remember me, last visit, etc.
  - `x.ua['uname'] = 'jb123'` will set the name variable in the `x.ua` variable accross requests.

See [Waxx Docs](https://www.waxx.io/doc/code) for more info.

#### A request is processed as follows:

1. HTTP request is received by Waxx (Use a reverse proxy/load balancer/https server like NGINX first for production)
2. The request is placed in a queue: `Waxx::Server.queue`
3. The request is popped off the queue by a Ruby green thread and parsed
4. The variable `x` is created with the request `x.req` and response `x.res` and DB connections in `x.db`.
5. The run method is called for the appropriate app (a namespaced RPC). All routes are: /app/act/[arg1/args2/arg3/...] => app is the module and act is the method to call with the args.
6. You output to the response using `x << "output"` or using helper methods: `App::Html.render(...)`
7. The response is returned to the client. Partial, chunked, and streamed responses are supported as well. You have direct access to the IO.

## Fast to Develop

Waxx was built with code maintainablity in mind. The following principles help in maintaining Waxx apps:

1. Simple to know where the code is located for any URI. A request to /person/list will start in the `app/person/person.rb` file and normally use the view defined in the file `app/person/list.rb`
2. Fields are defined upfront. The fields you want to use in your app are defined in the Object file `app/person/person.rb`
3. Field have attributes that make a lot of UI development simple (optional). has(email: {label: "Email Address" ...})`
4. Views allow you to see exactly what is on an interface and all the business logic. Only the fields on a view can be updated so it is impossible to taint the database by passing in extra parameters.
5. Most rendering is automatic unless you want to do special stuff. You can use pure Ruby functions or your favorite template engine. The View file `app/person/list.rb` contains all of the fields, joined tables, and layout for a view.
6. Full visibility into the external API and each endpoint's access control allows to immediate auditing of who can see and do what.

There are no routes.
All paths are `/:app/:act/:arg1/:arg2/...`.
The URL maps to an App and runs the act (method).
For example: `example.com/person/list` will execute the `list` method in the `App::Person` module.
This method is defined in `app/person/person.rb`.
Another example: A request to `/website_page/content/3` will execute the `content` method in the `App::WebsitePage` app and pass in `3` as the first parameter after 'x'.
There is a default app and a default method in each app.
So a request to `example.com/` will show the home page if the default app is `website` and the default method in website is `home`.


### File Structure
Waxx places each module in it's own directory. This includes the Object, Runner, Views, Layouts, and Tests.
I normally place my app-specific javascript and css in this same folder as well.
In this way, all of the functionality and features of a specific App or Module are fully self-contained.
However, you can optionally put your files anywhere and require them in your code.
So if you like all the objects to be in one folder you can do that.
If you work with a large team where backend and frontend people do not overlap, then maybe that will work for you.

This is a normal structure:

```
.
|-- app                         # Your apps go here. Also Waxx::App::Root
|   |-- app.rb                  # Site-specific methods
|   |-- html.rb                 # The shared HTML layout and helpers
|   |-- app                     # Customizable waxx helper apps (logging and error handling)
|   |   |-- app.rb              # App/generic functions
|   |   |-- error
|   |   |   |-- app_error.rb    # Error handler
|   |   |   |-- dhtml.rb        # Render a Dhtml error
|   |   |   |-- html.rb         # Render an Html error
|   |   |   `-- json.rb         # Render a Json error
|   |   |-- log
|   |   |   `-- app_log.rb      # Log to your chosen logging system
|   |-- company                 # An app
|   |   |-- company.rb          # An object and router for /company
|   |   `-- list.rb             # A view (fields and layout)
|   |-- person                  # The person app
|   |   |-- html.rb             # Shared HTML for the person app
|   |   |-- person.rb           # The Person object and /person methods
|   |   `-- profile.rb          # The Person::Profile view
|   |-- grp                     # Grp app (included in Waxx)
|   |   `-- grp.rb
|   |-- usr                     # Usr app (included in Waxx)
|   |   |-- email.rb
|   |   |-- grp
|   |   |-- html.rb
|   |   |-- list.rb
|   |   |-- password.rb
|   |   |-- record.rb
|   |   |-- usr.js
|   |   `-- usr.rb
|   `-- website                 # The website app (included in Waxx)
|       |-- html.rb             # Html for the website
|       |-- page                # website_page app
|       |   |-- list.rb         # List webpages
|       |   |-- record.rb       # Edit a webpage
|       |   `-- website_page.rb # WebsitePage object and methods
|       `-- website.rb          # Website Object and methods/routes
|-- bin
|   `-- waxx                    # The waxx bin does everything (on off buff make test deploy etc)
|-- db                          # Store database stuff here
|   `-- app                     # Migrations live in here (straight one-way SQL files). Each db has its own folder
|       |-- 0-waxx.sql          # The initial migration that adds support for migrations to the DB
|       `-- 201612240719-invoice.sql  # A migration YmdHM-name.sql (`waxx migration invoice` makes this)
|-- lib                         # The libraries used by your app (waxx is included)
|-- log                         # The log folder (optional)
|   `-- waxx.log
|-- opt                         # Config for each environment
|   |-- active -> dev           # Symlink to the active environment
|   |-- deploy.yaml             # Defines how to deploy to each environment
|   |-- dev                     # The dev environment
|   |   `-- config.yaml
|   |-- stage                   # The stage environment
|   |   |-- config.yaml
|       `-- deploy              # The script to deploy to stage (run on the stage server)
|   `-- prod                    # The production environment
|       |-- config.yaml
|       `-- deploy              # The script to deploy to stage (run on the production server(s))
|-- private                     # A folder for private files (served by the file app if included)
`-- public                      # The public folder (Web server should have this as the root)

```

The Waxx::Object has two purposes:

1. Specifies what fields/properties are in the table/object and what the attributes of the fields are. Like the renderer, validation, field label, etc. This is similar to a Model in MVC.
2. Specify the external interfaces to talk to the object's views. These are the routes and controllers combined.

If your object represents a database table, you extend with one of the following:

```
extend Waxx::Pg
extend Waxx::Mysql2
extend Waxx::Sqlite3
```

Other database connectors will be added. You are welcome to make a pull request ;-)

For example:

*app/person/person.rb:*

```ruby
module App::Person
  extend Waxx::Pg
  extend self

  # Specify the fields/attributes
  has(
    id: {pkey: true, renderer: "id"},
    first_name: {renderer: "text"},
    last_name: {renderer: "text"},
    email: {renderer: "email", validate: "email", required: true},
    bio: {renderer: "html"}
  )

  # Specify what interfaces are exposed (routes) and the access control (ACL)
  runs(
    # Handles /person by calling list defined below
    default: "list",

    # Handles /person/list or /person because "list" is the default runner
    list: {
      desc: "Show a list of people",
      acl: %w(admin), # User must be in the "admin" group to run this action
      get: lambda{|x| List.run(x)}  # How to respond to a GET request
    },

    # handles a request to /person/record/1
    record: {
      desc: "Edit a person record",
      acl: %w(admin), # User must be in the "admin" group to run this action
      # Each HTTP Request Type calls a different proc
      get: ->(x, id){ Record.run(x, id) },             # SELECT
      post: ->(x){ Record.run(x, x.req.post) },        # INSERT
      put: ->(x, id){ Record.run(x, id, x.req.post) }, # UPDATE
      delete: ->(x, id){ Record.run(x, id) },          # DELETE
    }
  )
end

# Require the views
require_relative 'list'   # The List View is defined here
require_relative 'record' # The Record View is defined here
```

A view is like a database view (not like a Rails view). The view specifies what tables/objects and fields/properties are going to be displayed and potentially edited. The Html layout module is like a Rails view. Other layouts include: Json, Csv, Pdf, Xlsx.

**app/person/list.rb** *(This is the view that lists the users)*

```ruby
module App::Person::List
  extend Waxx::View
  extend self

  has(
    :id,
    :first_name,
    :last_name,
    :email
    # This view does not include the bio field
  )

  module Html
    extend Waxx::Html
    extend self

    def get(x, data, message={})
      # This method appends to x and includes your site layout and nav.
      # The content attribute is what goes in the content area of the page.
      App::Html.page(x,
        title: "People",
        content: content(x, data)
      )
    end

    def content(x, data)
      # You put your HTML output here using:
      %(<p>HTHL or a template engine</p>)
    end

  end
end
```

**app/person/record.rb** *(This is the view to view, edit, update, and delete a record)*

```ruby
module App::Person::Record
  extend Waxx::View
  extend self

  has(
    :id,
    :first_name,
    :last_name,
    :email,
    :bio
  )

  module Html
    extend Waxx::Html
    extend self

    def get(x, data, message={})
      App::Html.page(
        title: "#{data['first_name']} #{data['last_name']}",
        content: content(x, data)
      )
    end

    def content(x, data)
      # You put your HTML output here using:
      %(<p>HTHL or a template engine</p>)
    end

    def post(x)
      # Following a post, redirect to the list view
      x.res.redirect "/person/list"
    end
    alias delete post
    alias put post

  end
end
```

When you create a view you get four data access methods automatically. This includes:

* get
* get_by_id (or by_id)
* post
* put
* delete

Only the feilds on the view can be gotten and manipulated. For example, we can call these methods from the console:

```ruby
waxx console
person = App::Person::Record.by_id(x, 16)
# => A hash of the record in the table with the ID of 16
```


## Relationships
Relationships in Waxx are defined in the field attributes. There are INNER JOINs, LEFT JOINs, and JOINs using a Join Table (many-to-many):

### INNER JOIN (is: name:table.field)

We will add a relationship between the Person and the Company:

```ruby
module App::Person
  extend Waxx::Pg
  extend self

  # Specify the fields/attributes
  has(
    id: {pkey: true, renderer: "id"},
    company_id: {is:"company:company.id"}, # "is:" defines a relationship
    first_name: {renderer: "text"},
    last_name: {renderer: "text"},
    email: {renderer: "email", validate: "email", required: true},
    bio: {renderer: "html"}
  )
end
```

Then in the list view, we can add the company that the person is associated with

```
module App::Person::List
  extend Waxx::View
  extend self

  has(
    :id,
    :first_name,
    :last_name,
    "company_name: company.name",
    :email
  )
end
```

In this case the attribute "company_name" will be added to the view and is the value of the "name" field in the company table. The syntax for this is `<name>: <relationship_name (as defined in the object)>.<field>`.

### LEFT JOIN (is: name:table.field+)

We will add an invoice and invoice_item table.

**Invoice Object**

```
module App::Invoice
  extend Waxx::Obj
  extend self

  # Specify the fields/attributes
  has(
    id: {pkey: true, is:"items:invoice_item.invoice_id+"},
    customer_id: {is:"company:company.id", required: true},
    invoice_date: {renderer: "date", required: true},
    terms: {renderer: "text", required: true},
    status: {renderer: "select", default: "Draft"}
  )
end
```

*Note: The + sign after the related attribute make this join a left join (Oracle style)*

INNER JOIN (If you don't want to show invoices with no items):

`id: {pkey: true, is:"items: invoice_item.invoice_id"}`

LEFT JOIN (If you want to show invoices with no items):

`id: {pkey: true, is:"items: invoice_item.invoice_id+"}`

**InvoiceItem Object**

```
module App::InvoiceItem
  extend Waxx::Pg
  extend self

  # Specify the fields/attributes
  has(
    id: {pkey: true, renderer: "id"},
    invoice_id: {is: "invoice:invoice.id", required: true},
    product_id: {is: "product:product.id", required: true},
    description: {renderer: "text"},
    quantity: {renderer: "number"},
    unit_price: {renderer: "money"}
  )
end
```

**Invoice::Items View**
This will show a list of all invoices and the items on the invoices:

```ruby
module App::Invoice::Items
  extend Waxx::View
  extend self

  has(
    :id,
    :invoice_date,
    "company: company.name",
    "product: product.name",
    "desc: items.description",
    "qty: items.quantity",
    "price: items.unit_price",
    {name: "total", sql_select: "items.quantity * items.unit_price"}
  )
end
```

This will generate the following SQL:

```sql
  SELECT   invoice.id, invoice.invoice_date, company.name as company, product.name as product,
      items.description as desc, items.quantity as qty, items.unit_price as price,
      (items.quantity * items.unit_price) as total
  FROM  invoice
      LEFT JOIN invoice_item AS items ON invoice.id = invoice_item.invoice_id
      INNER JOIN company ON invoice.customer_id = company.id
      INNER JOIN product ON items.product_id = product.id
```

The following attributes can be used in your layout (output)

`id, invoice_date, company, product, desc, qty, price, total`

### Many-to-Many Relationships

The join table is just another object in Waxx

```ruby
  # The Usr Object
  module App::Usr
    extend Waxx::Pg
    extend self

    has({
      id: {pkey: true, is:"group_member: usr_grp.usr_id+"},
      email: {validate: "email"},
      password_sha256 {renderer: "password", encrypt: "sha256", salt: true}
    })
  end

  # The Grp Object
  module App::Grp
    extend Waxx::Pg
    extend self

    has({
      id: {pkey: true, is:"group_members: usr_grp.grp_id+"},
      name: {required: true}
    })
  end

  # The Usr->Grp Join Table
  module App::UsrGrp
    extend Waxx::Pg
    extend self

    has({
      id: {pkey: true},
      usr_id: {required: true, is:"usr:usr.id"},
      grp_id: {required: true, is:"grp:grp.id"}
    })
  end

  # View that joins all three tables (show all users and groups they are in)
  module App::Usr::Groups
    extend Waxx::View
    extend self

    has(
      :id,
      :email,
      "group_id: group_member.grp_id",
      "group: grp.name"
    )
  end
```

Some explanation of the View:

* **group_id** is the name of the field on the view (you choose the name).
* **group_member.grp_id** causes the join table **usr_grp** to be LEFT JOINed in because the relationship "**group_member**" is defined in the attributes of **App::Usr.id**.
* **group** is the name of the group. (You define this as you please. Could be group_name just as well.)
* **grp** matched the **grp** relationship defined in the **App::UsrGrp.grp_id** field and causes and INNER JOIN on the **grp** table.
* The **group_members** relationship in **App::Grp.id** and the **usr** relationship in **App::UsrGrp.usr_id** are not used in this case because we start with `usr` and include `usr_grp` and then `grp`. If we started with `grp` and included `usr_grp` and `usr`, then those relationships would be used. If you are going in only one direction in your app, then you only need to define the relationships in the direction you are using.

The resulting SQL:

```sql
  SELECT usr.id, usr.email, group_member.grp_id AS group_id, grp.name AS group
  FROM   usr
  LEFT JOIN usr_grp AS group_member ON usr.id = group_member.usr_id
  JOIN grp ON group_member.grp_id = grp.id
```


The view will show all users and any groups they are in.

## Routing

Waxx is closer to an RPC (remote procedure call) system than a routed system.

### Arguments

`example.com/artist/list` maps to `app = "artist"` and `act = "list"` and will call the list method defined in App::Artist.runs().

Each slash-delimited argument after the first two are treated as arguments to the function:

`/artist/in/us/california/los-angeles` will feed into the following runner:

```
module App::Artist
  extend Waxx::Pg
  extend self

  runs(
    in: {
      desc: "Show a list of artists in an area",
      get: lambda{|x, country, state_prov, city|
        List.run(x, args: {country: country, state_prov: state_prov, city: city})
      }
    }
  )
end
```

In this case all three parameters are required. An error will be raised if the city is missing.
There are two options: Add default values or use a proc instead of a lambda:

```
get: proc{|x, country, state_prov, city| }
# If city is missing: /artist/in/us/colorado, then city will be nil

get: lambda{|x, country="us", state_prov="", city=""| }
# If city is missing: /artist/in/us/colorado, then city will be "" or whatever you set the default to

get: -> (x, country="us", state_prov="", city="") { }
# This is equivilant to the lambda example above
```

NOTE: You can use `return` in `lambda` and `->` constructs, but you need to use `break` in `proc` constructs to stop processing.

### Variable Act / not_found

What if you want the act be a variable like `/artist/david-bowie` or `/artist/motorhead`?

You define **`not_found`** in your Object runs method:

```
module App::Artist
  extend Waxx::Pg
  extend self

  runs(
    default: "list",
    list: {
      desc: "Show a list of artists: /artist or /artist/list",
      get: lambda{|x|
        # Sort the results based on the query string: /artist?order=name
        List.run(x, order: x['order'])
      }
    }
    profile: {
      desc: "Show an artist profile based on their slug in the URL: /artist/profile/<slug>",
      get: lambda{|x, artist_slug|
        # Set the slug attribute from the passed in variable
        Profile.run(x, args: {slug: artist_slug})
      }
    }
    not_found: {
      desc: "Show an artist profile based on their slug in the URL: /artist/<slug>",
      get: lambda{|x|
        # Set the slug attribute to the act
        Profile.run(x, args: {slug: x.act})
      }
    }
  )
end
```

Note: In the above example `/artist/led-zeppelin` and `/artist/profile/led-zeppelin` will show the same result. (For SEO you should only use one of these or include a canonical meta attribute.)

There is also a `not_found` method defined at the top level as well. By default Waxx will look for a website_page where the URI matches the website_page.uri. You can change this behavior by adding a `App.not_found` method to `app/app.rb`.

## Access Control

Waxx includes a full user and session management system. The following apps are installed by default:

```
  app/grp
  app/usr
  app/usr/grp
```

Using these apps allow you to add users and groups and put users in groups. You define your access control lists for each method. There are several levels of permissions. The following seven code blocks are parts of the same file:

### Example ACLs
ACLs are defined as a attribute (`acl: [nil|string|array|hash|lambda]`) of each method options hash.

The following code blocks are different examples of the acl attribute in practice.

**Start: app/product/product.rb**

```
  module App::Product
    extend Waxx::Pg
    extend self

    runs(
      default: "list",
```

#### Public

No ACL defined:

```
      list: {
        desc: "Show a list of products (public)",
        # No acl attribute so it is public
        get: lambda{|x|
          List.run(x, order: x['order'])
        }
      },
```

#### Any logged in user

```
      exclusives: {
        desc: "Show a list of exclusive products",
        acl: "user", # The name of the quasi group "user" (anyone who is logged in)
        get: lambda{|x|
          List.run(x, order: x['order'])
        }
      },
```

#### In any group:
User must be in one of the groups listed

```
      private: {
        desc: "Show a list of private products",
        acl: %w(big_spender deal_seaker admin product_manager),
        get: lambda{|x|
          List.run(x, order: x['order'])
        }
      },
```

#### In a group depending on request method:
User must be in one of the groups listed to run a specific request method

```
      record: {
        desc: "Show a list of products (public)",
        acl: {
          get: %w(user), # Any logged in user can GET
          post: %w(admin product_manager) # Only admin and product_manager can POST
        },
        get: lambda{|x, id|
          Record.run(x, id: id)
        },
        post: lambda{|x, id|
          Record.run(x, id: id, data: x.req.post)
        }
      },
```

#### Lambda/Proc (total control ACL):
If the proc or lambda returns true, then the user is allowed to proceed, otherwise an error is returned. The proc is passed `x`

```ruby
      special: {
        desc: "View and edit a product from a specific IP
             or if the user has a secret key in their session",
        acl: -> (x) {
          x.req.env['X-REAL-IP'] == "10.10.10.10" or x.usr['secret'] == "let-me-in"
        },
        get: -> (x, id) { Record.run(x, id: id) },
        post: -> (x, id) { Record.run(x, id: id, data: x.req.post) }
      },

      mine: {
        desc: "View and edit a product owned by the user",
        acl: -> (x) {
          # Get the product.owner_id from the database
          product = by_id(x, x.oid, "owner_id")
          # Return true if the logged in user is the owner
          product['owner_id'] == x.usr['id']
        },
        get: -> (x, id) { Record.run(x, id: id) },
        post: -> (x, id) { Record.run(x, id: id, data: x.req.post) }
      },
```

End the object file

```
      )
  end
```

**End: app/product/product.rb**

## Quick Examples

A fast JSON response for an autocomplete form field

If you want to have a quick JSON response for an autocomplete -- Just use a Waxx::Object and bypass the Waxx::View and layout (Json, HTML, etc.).
Direct access is available to the database driver with `x.db.app` where `app` is the name of the database connection defined in your config.yaml file.
In this case, as a user types in an autocomplete input box, the browser sends a request to: `/artist/autocomplete.json?q=da`
When the .json extension is used, the response content type will be application/json.
What the user types would be in the `q` attribute.

PostgreSQL DB:

```ruby
module App::Artist
  extend Waxx::Object
  extend self

  # Notice that "has" is not specified so you can't use waxx get and post methods.
  # You are just talking straight to the database and formatting the output as json
  # and sending that straight to x. The `x['q']` is the value of the q query parameter.

  runs(
    autocomplete: {
      desc: "Show a list of artists that match the 'q' param",
      get: -> (x) {
        x << x.db.app.exec("
          SELECT id, name
          FROM artist
          WHERE name ILIKE $1
          ORDER BY name
          LIMIT 20",
          ["#{x['q']}%"]
        ).map{|rec| rec }.to_json
      }
    }
  )
end
```

If you are using Mongo, you can do it like this:

```ruby
module App::Artist
  extend Waxx::Object
  extend self

  runs(
    autocomplete: {
      desc: "Show a list of artists that match the 'q' param",
      get: -> (x) {
        x << x.db.app['artist']
          .find({name: /^#{x['q']}/})
          .projection({name:1}) # you get _id automatically
          .sort({name:1})
          .limit(20)
        .map{|rec| rec }.to_json
      }
    }
  )
end
```

Both of these should return a response in less than one millisecond (assuming your data is indexed and running on decent hardware).

That is the intro. Give it a whirl.

Please send any feedback to dan@waxx.io


