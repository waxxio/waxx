app.modal = {
  btn: {
    ok: function(act){
      return '<button type="button" class="btn btn-primary" data-dismiss="modal" onclick="'+act+'()">OK</button>';
    },
    okClose: '<a class="btn btn-primary" href="#modal/close">OK</a>',
    close: function(label){
      label = label || "Close";
      return '<button type="button" class="btn btn-secondary bg-dark" data-dismiss="modal">'+label+'</button>';
    },
    make: function(act, label, style){
      style = style || "primary";
      return '<button type="button" class="btn btn-'+style+'" onclick="'+act+'()">'+label+'</button>';
    }
  },
  closeButton: '<button type="button" class="btn btn-secondary bg-dark" data-dismiss="modal">Close</button>',
  open: function(title, body, footer, size){
    if(size){$('.modal-dialog').addClass('modal-'+size);}
    else{$('.modal-dialog').removeClass('modal-lg').removeClass('modal-sm');}
    $('#modal .modal-title').html(title);
    $('#modal .modal-body').html(body);
    $('#modal .modal-footer').html(footer);
    $('#modal').modal('show');
  },
  alert: function(title, body){
    this.open(title, body, this.btn.okClose);
    $('.modal .btn-primary').focus();
  },
  confirm: function(title, body, yes, no){
    this.open(title, body, '<button type="button" class="btn btn-primary" onclick="'+yes+'">Yes</button>' + app.modal.btn.close("No"));
  },
  prompt: function(title, msg, btn){
    this.open(title,
      msg+'<input type="text" class="form-control m-t" id="modal-prompt-field">',
      app.modal.btn.close('Cancel') + btn
    );
  },
  close: function(){
    $('#modal').modal('hide');
    // This should not be needed but there is some bug somewhere that is causing the backbround to stay active.
    // (It may be a race condition with multiple modals opening and closing.)
    $('.modal-backdrop').remove();
  }
};
