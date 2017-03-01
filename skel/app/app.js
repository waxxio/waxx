app = {
  usr: {},
  host: location.host,
  show: function(name){
    $('body').attr('data-app',name);
  },
  loadNav: function(){
    $('#header').load("/app/header.dhtml");
    $('#nav1').load("/app/nav1.dhtml");
  },
  after_login_default: function(){
    location = "/";
  },
  // This function get over-written by other apps that ask·
  // the user to login before doing something. (Like create·
  // an issue or post a comment)
  after_login: function(){
    location = "/";
  },
  group: function(grp){
    if(!app.usr.grp){return false;}
    return app.usr.grp.indexOf(grp) != -1;
  },
  groups: function(){
    var wanted = arguments.length;
    var has = 0;
    $.each(arguments, function(i,a){
      if(app.usr.grp.indexOf(a) > -1){
        has += 1;
      }
    })
    return wanted == has;
  }
}
