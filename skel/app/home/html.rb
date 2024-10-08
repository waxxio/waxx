module App::Home::Html
  extend Waxx::Html
  extend self

  def welcome(x)
    App::Html.render(x, title: "Welcome to Waxx", content: %(
      <h1>Waxx</h1>
      <p>
        This is the default home page of your Waxx app. 
        The file is <code>app/home/html.rb</code>
      </p>
    ))
  end

end
