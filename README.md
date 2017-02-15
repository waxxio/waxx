# WAXX - Web Application X(x)

** WARNING: WAXX is in early development (alpha) and the API may change frequently. Do not build large production apps with it yet! **

The WAXX Framerwork is a high perfomance, functional-inspired (but not truly functional), web application development environment written in Ruby and inspired by Go and Haskel. 

## Goals

1. High Perfomance (similar to Node and Go)
2. Easy to grok
3. Fast to develop
3. Efficient to maintain
4. Fast and easy to deploy
5. Minimal dependencies (Currently only your database lib: PG, Mongo, etc.)

## Target Users

The WAXX Framework was developed to build CRUD applications and REST and RPC services. It scales very well on multi-core machines and is [will be] suitable for very large deployments.

## Who's Behind This

WAXX is a project of [ePark Labs](https://www.eparklabs.com/) and was developed by [Dan Fitzpatrick](https://djf.co/). 

## How Does it Compare to Rails

Waxx is an order order of magnitude faster than Rails. It is easier to understand and trace the code. Waxx is not an MVC framework, although some concepts are similar. The introduction below includes some comparisons to Rails.

## Hello World

_app/hello/hello.rb:_

  module App::Hello
    extend Waxx::Object
    extend self
    init

    runs({
      default: "world",
      world: {
        desc: "This says Hello World",
        get: lambda{|x|
          x << "Hello World!"
        }
      }
    })
  end

URL: example.com/hello or example.com/hello/world

returns "Hello World"

NOTE: This is not the way you build a normal app. Just here because everyone wants to see a Hello World example.

## Introduction to WAXX

###TL;DR:
  gem install waxx
  waxx init site
  cd site
  waxx on
  
Visit [http://localhost:7777/](http://localhost:7777/) and follow the directions. If you want a different port, edit `etc/active/config.yaml` first.

### High Performance
WAXX is multi-threaded and each request is placed into a thread pool (queue) and then a thread will process it. You specify the number of threads in the config file. Each thread is prespawned and each thread makes it's own database connection. Requests are received and put into a FIFO request queue. The threads work through the queue. Each request, including session management, a database query, access control, and rendering in HTML or JSON is approximately 1-2ms (on a modern 2016 Xeon server). With additional libraries, WAXX also easily generates XML, XLSX, CSV, and PDF data. 

### Easy to Grok 
Waxx has no Classes. It is Module-based and the Modules have methods (functions). Each method within a Module is given parameters and the method runs in isolation. There are no instance variables. Consequently, it is very easy to understand what any method does and it is very easy to test methods. You can call any method in the whole system from the console. Passing in the same variables will always return the same result.

There are some basic terminologies in WAXX:

* Object: A database table or database object
* Object `has` fields (an array of Hashes). A field is both a database field/column/attribute and a UI control (for HTML apps) 
* Field `is` (represents) a single object (INNER JOIN) or many related objects (LEFT JOIN)
* Object `runs` a URL path - business logic (normally get from or post to a view)
* View: Like a DB view -- fields from one or more tables/objects
* Html, Json, Xlsx, Tab, Csv, Pdf, etc.: How to render the view
* x is a variable that is passed to nearly all methods and contains the request (`x.req` contains: get and post vars, request cookies, and environment) and response (`x.res` contains the status, response cookies, headers, and content body) 

A request is processed as follows:

1. [The request is received by the server (or a reverse proxy/load balancer like HAProxy or NGINX) | The request is received directly by Waxx (for development only)]
2. The request is passed to the Waxx server and placed in a queue: `Waxx::Server.queue`
3. The request is popped off the queue by a Ruby green thread and parsed
4. The variable `x` is created with the request `x.req` and response `x.res`.
5. The run method is called for the appropriate app (a namespaced RPC). All routes: /app/act/[arg1/args2/arg3/...] => app is the module and act is the method to call with the args.
6. You output to the response using `x << "output"` or using helper methods: `App::Html.page(...)`
7. The response is returned to the client. Partial, chunked, and streamed responses are supported as well.  


## Fast to Develop

1. Simple to know where the code is located for any URI -- no need to chase down route logic
2. Fields are defined upfront
3. Field have attributes that make a lot of UI development simple (optional)
4. Views allow you to see exactly what is on an interface and all the business logic
5. Most rendering is automatic unless you want to do special stuff. You can use pure Ruby functions or your favorite template engine.

There are no routes. All paths are `/:app/:act/:arg1/:arg2/...`. The URL maps to an App and runs the act (method). For example: `example.com/person/list` will execute the `list` method in the `App::Person` module. This method is defined in `app/person/person.rb`. Another example: A request to `/website_page/content/3` will execute the `content` method in the `App::WebsitePage` app and pass in `3` as the first parameter after 'x'. There is a default app and a default method in each app. So a request to `example.com/` will show the home page if the default app is `website` and the default method in website is `home`.



### File Structure
WAXX places each module in it's own directory. This includes the Object, Runner, Views,  Layouts, and Tests. I normally place my app-specific javascript and css in this same folder as well. In this way, all of the functionality and features of a specific App or Module are fully self-contained. However, you can optionally put your files anywhere and require them in your code. So if you like all the objects to be in one folder you can do that. If you work with a large team and Ruby and Javascript people do not overlap, then maybe that will work for you.

This is a normal structure:

      

```
WAXX.ROOT
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
|   |-- init.dmp                # SQL dump of the initial state of the DB
|   `-- migrations              # Migrations live in here (straight one-way SQL files)
|       |-- 0-waxx.sql          # The initial migration that adds support for migrations to the DB
|       `-- 201602240719-invoice.sql  # A migration YmdHM-name.sql (`waxx migration invoice` makes this)
|-- etc                         # Config for each environment
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
|-- lib                         # The libraries used by your app (waxx is included)
|-- log                         # The log folder (optional)
|   `-- waxx.log
|-- private                     # A folder for private files (served by the file app if included)
`-- public                      # The public folder (Web server should have this as the root)
   
```

The Waxx::Object has two purposes:

1. Specifies what fields/properties are in the table/object and what the attributes of the fields are. Like the renderer, validation, field label, etc. This is similar to a Model in MVC.
2. Specify the external interfaces to talk to the object's views. These are the routes and controllers combined.

**app/person/person.rb:**
  
  module App::Person
    extend Waxx::Object
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
      # Handles /person by calling list(x)
      default: "list",
      # Handles /person/list or /person because "list" is the default runner
      list: {
        desc: "Show a list of people",
        acl: %w(admin), # User must be in the "admin" group to run this action
        get: lambda{|x| List.run(x)}
      },
      # handles a request to /person/record/1
      record: {
        desc: "Edit a person record",
        acl: %w(admin), # User must be in the "admin" group to run this action
        get: lambda{|x,id| Record.run(x, id)},
        post: lambda{|x,id| Record.run(x, id, x.req.post)},
        delete: lambda{|x,id| Record.run(x, id)},
      }
    )
  end
  
  # Require the views
  require_relative 'list'
  require_relative 'record'

A view is like a database view (not like a Rails view). The view specifies what tables/objects and fields/properties are going to be displayed and potentially edited. The Html layout module is like a Rails view. Other layouts include: Json, Csv, Pdf, Xlsx. 

**app/person/list.rb** *(This is the view that lists the users)*

  module App::Person::List
    extend Waxx::View
    extend self
    
    has(
      :id,
      :first_name,
      :last_name,
      :email
    )
    
    module Html
      extend Waxx::Html
      extend self
      
      def get(x, data, message={})
        App::Html.page(
          title: "People",
          content: content(x, data)
        )
      end
      
      def content(x, data)
        
      end
      
      def post(x)
        x.res.redirect "/person"
      end
    end
  end
  

**app/person/record.rb** *(This is the view to view, edit, update, and delete a record)*

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
          title: "People",
          content: content(x, data)
        )
      end
      
      def content(x, data)
        
      end
      
      def post(x)
        x.res.redirect "/person"
      end
    end
  end
  
## Relationships
Relationships in Waxx are defined in the field attributes. There are INNER JOINs, LEFT JOINs, and JOINs using a Join Table (many-to-many):

### INNER JOIN (is:)

We will add a relationship between the Person and the Company:

  module App::Person
      extend Waxx::Obj
      extend self

      # Specify the fields/attributes
      has(
          id: {pkey: true, renderer: "id"},
          company_id: {is:"company:company.id"},
          first_name: {renderer: "text"},
          last_name: {renderer: "text"},
          email: {renderer: "email", validate: "email", required: true},
          bio: {renderer: "html"}
      )
      ...

Then in the list view, we can add the company that the person is associated with

  module App::Person::List
    extend Waxx::View
    extend self
    
    has(
      :id,
      :first_name,
      :last_name,
      "company_name: company.name"
      :email
    )
    ...
    
In this case the attribute "company_name" will be added to the view and is the value of the "name" field in the company table. The syntax for this is `<name>: <relationship_name (as defined in the object)>.<field>`.

### LEFT JOIN (is:+)

We will add an invoice and invoice_item table.

**Invoice Object**

  module App::Invoice
      extend Waxx::Obj
      extend self

      # Specify the fields/attributes
      has(
          id: {pkey: true, is:"items:invoice_item.invoice_id+"},
          customer_id: {is:"company:company.id", required: true},
          invoice_date: {renderer: "date", required: true, default: proc{Time.new.strftime('%d-%b-%Y')},
          terms: {renderer: "text", required: true},
          status: {renderer: "select", default: "Draft"
      )
    end

*Note: The + sign after the related attribute make this join a left join (Oracle style)*

INNER JOIN (If you don't want to show invoices with no items): 

  id: {pkey: true, is:"items: invoice_item.invoice_id"}
  
LEFT JOIN (If you want to show invoices with no items):

  id: {pkey: true, is:"items: < invoice_item.invoice_id"}

Many-to-Many JOIN (The invoice has zero on more tags stored in the item_tag table NOTE: THIS MAY CHANGE!):

  id: {pkey: true, is:"tags: tag_item.item_id.tag_id tag.id"}

**InvoiceItem Object**

  module App::InvoiceItem
      extend Waxx::Obj
      extend self

      # Specify the fields/attributes
      has(
          id: {pkey: true, renderer: "id", has:"items:invoice_item.invoice_id"},
          invoice_id: {is:"invoice:invoice.id", required: true},
          product_id: {is:"product:product.id", required: true},
          description: {renderer: "text"},
          quantity: {renderer: "number"},
          unit_price: {renderer: "money"}
      )
    end
    

**Invoice::Items View**
This will show a list of all invoices and the items on the invoices:

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
  
This will generate the following SQL:

  SELECT   invoice.id, invoice.invoice_date, company.name as company, product.name as product, 
      items.description as desc, items.quantity as qty, items.unit_price as price,
      (items.quantity * items.unit_price) as total
  FROM  invoice 
      LEFT JOIN invoice_item AS items ON invoice.id = invoice_item.invoice_id
      INNER JOIN company ON invoice.customer_id = company.id
      INNER JOIN product ON items.product_id = product.id
      
The following attributes can be used in your layout (output)

  id, invoice_date, company, product, desc, qty, price, total

### Many-to-Many Relationships

The join table is just another object in Waxx

  # The Usr Object
  module App::Usr
    extend Waxx::Object
    extend self
    
    has({
      id: {pkey: true, is:"group_member: usr_grp.usr_id+"},
      email: {validate: "email"},
      password_sha256 {renderer: "password", encrypt: "sha256", salt: true}
    })
  end

  # The Grp Object
  module App::Grp
    extend Waxx::Object
    extend self
    
    has({
      id: {pkey: true, is:"group_members: usr_grp.grp_id+"},
      name: {required: true}
    })
  end

  # The Usr->Grp Join Table
  module App::UsrGrp
    extend Waxx::Object
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
  
Some explanation of the View:

* **group_id** is the name of the field on the view (you choose the name).
* **group_member.grp_id** causes the join table **usr_grp** to be LEFT JOINed in because the relationship "**group_member**" is defined in the attributes of **App::Usr.id**.
* **group** is the name of the group. (You define this as you please. Could be group_name just as well.)
* **grp** matched the **grp** relationship defined in the **App::UsrGrp.grp_id** field and causes and INNER JOIN on the **grp** table.
* The **group_members** relationship in **App::Grp.id** and the **usr** relationship in **App::UsrGrp.usr_id** are not used in this case because we start with `usr` and include `usr_grp` and then `grp`. If we started with `grp` and included `usr_grp` and `usr`, then those relationships would be used. If you are going in only one direction in your app, then you only need to define the relationships in the direction you are going.

The resulting SQL:

  SELECT   usr.id, usr.email, group_member.grp_id AS group_id, grp.name AS group
  FROM  usr
      LEFT JOIN usr_grp AS group_member ON usr.id = group_member.usr_id
      JOIN grp ON group_member.grp_id = grp.id



The view will show all users and any groups they are in.

## Routing

Waxx is closer to an RPC (remote procedure call) system than a routed system.

### Arguments

`example.com/artist/list` maps to `app = "artist"` and `act = "list"` and will call the list method defined in App::Artist.runs().

Each slash-delimited argument after the first two are treated as arguments to the function:

`/artist/in/us/california/los-angeles` will feed into the following runner:


  module App::Artist
    extend Waxx::Object
    extend self
    init
    
    runs({
    in: {
      desc: "Show a list of artists in an area",
      get: lambda{|x, country, state_prov, city|
      List.run(x, args: {country: country, state_prov: state_prov, city: city})
      }
    }
    )
  end
  
In this case all three parameters are required. An error will be raised of the city is missing. There are two options: Add default values or use a proc instead of a lambda:

  get: lambda{|x, country="us", state_prov="", city=""|
  # If city is missing: /artist/in/us/colorado, then city will be "" or whatever you set the default to
  
  get: proc{|x, country, state_prov, city|
  # If city is missing: /artist/in/us/colorado, then city will be nil
  
### Variable Act / not_found

What if you want the act be a variable like `/artist/david-bowie` or `/artist/motorhead`? 

You define **`not_found`** in your Object runs method:

  module App::Artist
    extend Waxx::Object
    extend self
    init
    
    runs({
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
    })
  end
  
Note: In the above example `/artist/led-zeppelin` and `/artist/profile/led-zeppelin` will show the same result. (For SEO you should only use one of these or include a canonical meta attribute.)

There is also a `not_found` method defined at the top level as well. By default Waxx will look for a website_page where the URI matches the website_page.uri. You can change this behavior by adding a `not_found` method to `app/app.rb`.

## Access Control

Waxx includes a full user and session management system. The following apps are installed by default:

  app/grp
  app/usr
  app/usr/grp
  
Using these apps allow you to add users and groups and put users in groups. You define your access control lists for each method. There are several levels of permissions. The following seven code blocks are parts of the same file:

### Example ACLs
ACLs are defined as a attribute (`acl: [nil|string|array|hash|lambda]`) of each method options hash.

**Start: app/product/product.rb**

  module App::Product
    extend Waxx::Object
    extend self
    
    runs(
      default: "list",
      
#### Public
No ACL defined:

      list: {
        desc: "Show a list of products (public)",
        # No acl attribute so it is public
        get: lambda{|x|
          List.run(x, order: x['order'])
        }
      },
      
#### Any logged in user

      exclusives: {
        desc: "Show a list of exclusive products",
        acl: "user", # The name of the quasi group "user"
        get: lambda{|x|
          List.run(x, order: x['order'])
        }
      },
      
#### In any group:
User must be in one of the groups listed

      private: {
        desc: "Show a list of private products",
        acl: %w(big_spender deal_seaker admin product_manager),
        get: lambda{|x|
          List.run(x, order: x['order'])
        }
      },
      
#### In a group depending on request method:
User must be in one of the groups listed to run a specific request method

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
      
#### Lambda/Proc (total control ACL):
If the proc or lambda returns true, then the user is allowed to proceed, otherwise an error is returned. The proc is passed x

      special: {
        desc: "View and edit a product from a specific IP 
             or if the user has a secret key in their session",
        acl: lambda{|x|
          x.req.env['X-REAL-IP'] == "10.10.10.10" || x.usr['secret'] == "let-me-in"
        },
        get: lambda{|x, id| Record.run(x, id: id)},
        post: lambda{|x, id| Record.run(x, id: id, data: x.req.post)}
      },

      mine: {
        desc: "View and edit a product owned by the user",
        acl: lambda{|x|
          # Get the product.owner_id from the database
          product = get_by_id(x, x.oid, "owner_id")
          # Return true if the logged in user is the owner
          product['owner_id'] == x.usr['id']
        },
        get: lambda{|x, id| Record.run(x, id: id)},
        post: lambda{|x, id| Record.run(x, id: id, data: x.req.post)}
      },

End the object file

      )
  end
  
**End: app/product/product.rb**

That is it for now. More documentation to come soon.


