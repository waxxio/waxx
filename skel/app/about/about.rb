module App::About
  extend Waxx::Object
  extend self

  runs(
    index: {
      desc: "The about main page.",
      get: -> (x) {
        App::Html.page(x, title: "About", content: %(
          This is the main about page.
        ))
      }
    },
    privacy: {
      desc: "The privacy policy",
      get: -> (x) {
        App::Html.page(x, title: "Privacy Policy", content: %(
          You can pull this content from the file system or the database or just leave it in the code.
        ))
      }
    },
    terms: {
      desc: "The terms of use",
      get: -> (x) {
        App::Html.page(x, title: "Terms of Use", content: %(
          You can pull this content from the file system or the database or just leave it in the code.
        ))
      }
    },
  )

end
