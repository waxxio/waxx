module App::AppError::Json
  extend Waxx::Json
  extend self

  def get(x, title, message)
    x << {ok: false, title: title, message: message}.to_json
  end
end
