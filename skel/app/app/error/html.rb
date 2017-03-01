module App::AppError::Html
  extend Waxx::Html
  extend self

  def get(x, title, message)
    App::Html.page(x, title: title, content: h(message))
  end
end
