module App::AppError::Pdf
  extend Waxx::Pdf
  extend self

  def get(x, title, message)
    x.res['Content-Type'] = Waxx::Http.content_types[:pdf]
    pdf = new_doc
    pdf.text "<b>#{title}</b>"
    pdf.text "#{message}"
    render_file(x, pdf)
    return_file(x)
  end
end
