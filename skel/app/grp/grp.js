app.grp = {
  humanClick: function(icon){
    $('#bot_nav .btn-primary').removeClass('btn-primary').addClass('btn-link');
    $('#'+icon).removeClass('btn-link').addClass('btn-primary');
    $('#bot_check').val(icon);
  },
  passwordNew: function(pw1, pw2, btn){
    var score = app.passwordScore($(pw1).val());
    var match = $(pw1).val() == $(pw2).val();
    app.passwordStrengthMeter(score, pw1+"-status", pw1+"-meter");
    app.passwordMatchIcon(pw1, pw2);
    $(btn).attr('disabled',!(match && score >= 60));
  },
  // Thanks to tm_lv on stackoverflow
  passwordScore: function(pw){
    var score = 0;
    if (!pw){return score;}
    // award every unique letter until 5 repetitions
    var letters = new Object();
    for (var i=0; i<pw.length; i++) {
      letters[pw[i]] = (letters[pw[i]] || 0) + 1;
      score += 5.0 / letters[pw[i]];
    }
    // bonus points for mixing it up
    var variations = {
      digits: /\d/.test(pw),
      lower: /[a-z]/.test(pw),
      upper: /[A-Z]/.test(pw),
      nonWords: /\W/.test(pw),
    }
    variationCount = 0;
    for (var check in variations) {
      variationCount += (variations[check] == true) ? 1 : 0;
    }
    score += (variationCount - 1) * 10;
    return parseInt(score);
  },
  passwordStrengthMeter: function(score, text, meter){
    $(meter).css('width',Math.min(score, 100)+"%");
    if (score >= 80){
      $(text).html(score + " Strong");
      $(meter).css('background-color','green');
    }else if (score >= 60){
      $(text).html(score + " Good");
      $(meter).css('background-color','orange');
    }else if (score >= 30){
      $(text).html(score + " Weak");
      $(meter).css('background-color','red');
    }else{
      $(text).html(score + " Continue");
      $(meter).css('background-color','#aaa');
    }
  },
  passwordMatchIcon: function(pw1, pw2){
    if($(pw1).val() == $(pw2).val()){
      $(pw2+"-icon")
      .removeClass('glyphicon-unchecked')
      .addClass('glyphicon-check')
      .css('color','green');
    }else{
      $(pw2+"-icon")
      .removeClass('glyphicon-check')
      .addClass('glyphicon-unchecked')
      .css('color','red');
    }
  }
}
