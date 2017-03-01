module App::AppLog 
  extend Waxx::Object
  extend self
  init

  def log(x, cat:'', name:'', value:'', id:nil)
    x.db.exec("INSERT INTO app_log
      (usr_id, category, name, value, related_id, ip_address)
      VALUES ($1, $2, $3, $4, $5, $6)",
      [x.usr['id'], cat, name, value, id, x.req.env['X-Forwarded-For']]
    )
  end

end
