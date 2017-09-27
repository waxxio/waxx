module App::AppError::Dhtml
  extend Waxx::Html
  extend self

  def get(x, title, message)
    x << %(<div><strong>#{h title}</strong></div>
    <div><code>#{(h message).gsub("\n","<br>")}</code></div>)
  end
end
