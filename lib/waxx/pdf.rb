# Waxx Copyright (c) 2016 ePark labs Inc. & Daniel J. Fitzpatrick <dan@eparklabs.com> All rights reserved.
# Released under the Apache Version 2 License. See LICENSE.txt.

# require 'prawn' to use PDFs

module Waxx::Pdf

  def new_doc(margin:50, orientation: "portrait", info: {})
    Prawn::Document.new(:margin=>margin, :orientation=>orientation, :info=>info)
  end

  def doc_info(
    x,
    title: "Untitled",
    author: nil,
    subject: "",
    keywords: "",
    creator: "WAXX waxx.io",
    producer: "Prawn",
    creation_date: Time.new
  )
    {
    :Title => title,
    :Author => author || "#{x.usr['un']}",
    :Subject => subject,
    :Keywords => keywords,
    :Creator => creator,
    :Producer => producer,
    :CreationDate => creation_date
    }
  end

  def file_path(x)
    "#{Waxx::Root}/tmp/#{Time.new.strftime('%Y%m%dT%H%M%S')}-u#{x.usr['id']}.pdf"
  end

  def get
    pdf = new_doc
    pdf.text "Hello from WAXX. You need to implement the get method in your layout. Then call render_file & return_file"
    render_file(x, pdf)
    return_file(x)
  end

  def render_file(x, pdf, path)
    pdf.render_file path
  end

  def return_file(x, path)
    File.open(path, "rb"){|f| x << f.read}
  end

  def show_grid(pdf)
    existing_color = pdf.stroke_color?
    pdf.stroke_color Color::RGB.new(230, 230, 255)
    (0..800).step(10){|a|
      pdf.stroke_color Color::RGB.new(130, 130, 255) if (a % 100).zero?
      pdf.line(a,0,a,620).stroke
      pdf.stroke_color Color::RGB.new(230, 230, 255) if (a % 100).zero?
    }

    (0..620).step(10){|b|
      pdf.stroke_color Color::RGB.new(130, 130, 255) if (b % 100).zero?
      pdf.line(0,b,800,b).stroke
      pdf.stroke_color Color::RGB.new(230, 230, 255) if (b % 100).zero?
    }
    pdf.stroke_color existing_color
  end

end
