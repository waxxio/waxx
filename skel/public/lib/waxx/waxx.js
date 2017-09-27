waxx = {
  href: function(ev){
    console.log(ev);
    // If the target is not us return
    if(ev.currentTarget.target != "" && ev.type != "popstate"){
      console.log("target not us")
      return true;
    }
    // If not an http[s] link return
    if(/^http/.test(ev.currentTarget.protocol) == false && ev.type != "popstate"){
      console.log("not http/s link")
      return true;
      //ev.preventDefault();
    }
    // If not our host
    if(ev.currentTarget.host != app.host && ev.type != "popstate"){
      console.log("other host")
      return true; // location = ev.currentTarget.href;
    }
    // Run the hash
    if(ev.currentTarget && ev.currentTarget.hash){
      var hash = ev.currentTarget.hash;
      if(hash != undefined && hash != ""){
        if(waxx.runHash(hash)){
          ev.preventDefault();
          return false;
        }
        return true;
      }
    }
    // Push the state if this is not a back/forward nav
    if(ev.originalEvent.type != "popstate"){
      window.history.pushState({},ev.currentTarget.title, ev.currentTarget.pathname);
    }
    // Run the URI
    if(waxx.runURI()){
      console.log("runURI")
      ev.preventDefault();
    }
    // else: If no app/act continue away from this page
  },
  runHash: function(hash){
    var parts = hash.replace("#","").split("/");
    var ap = parts[0];
    var act = parts[1];
    var args = parts.slice(2,99);
    if(act != undefined){
      app[ap][act].apply(this, args);
      return true;
    }
    return false;
  },
  runURI: function(){
    var parts = location.pathname.split("/");
    if(location.pathname == "/"){
      parts = app.default_pathname.split("/");
    }
    var ap = parts[1];
    var act = parts[2];
    var args = parts.slice(3,99);
    //console.log("app["+ap+"]["+act+"].apply(this, "+args.join(",")+")");
    if(app[ap] != undefined && act != undefined && app[ap][act] != undefined){
      app[ap][act].apply(this, args);
      return true;
    }
    //console.log("Unknow app/act");
    return false;
  },
  qs: function(str){
    return encodeURIComponent(str);
  },
  ta: document.createElement('textarea'),
  esc: function(str){
    waxx.ta.textContent = str;
    return waxx.ta.innerHTML;
  },
  h: function(str){
    waxx.ta.textContent = str;
    return waxx.ta.innerHTML;
  },
  query: function(query_string){
    query_string = query_string || location.search;
    return query_string.substring(1).split(/[;&]/).reduce(function(result, value) {
      var parts = value.split('=');
      if (parts[0]) result[decodeURIComponent(parts[0])] = decodeURIComponent(parts[1]);
        return result;
    }, {});
  },
  fileSize: function(sz){return filesize(sz);},
  cookie: function(name, value, days) {
    if(value === undefined){return waxx.cookies(name)}
    if(value === null){return waxx.cookie(name,"",-1)}
    if (days) {
        var date = new Date();
        date.setTime(date.getTime()+(days*24*60*60*1000));
        var expires = "; expires="+date.toGMTString();
    }
    else var expires = "";
    document.cookie = name+"="+waxx.qs(value)+expires+"; path=/";
  },
  cookies: function(name) {
    var nameEQ = name + "=";
    var ca = document.cookie.split(';');
    for(var i=0;i < ca.length;i++) {
        var c = ca[i];
        while (c.charAt(0)==' ') c = c.substring(1,c.length);
        if (c.indexOf(nameEQ) == 0) return c.substring(nameEQ.length,c.length);
    }
    return null;
  }
};
