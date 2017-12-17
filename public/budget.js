function hover_functions(){
  $('.expense-row').hover(function(){
    var hlClass = ".expense-row.expense-" + $(this).attr("data-id");
    $(hlClass).addClass("expense-hl");
  }, function() {
    var hlClass = ".expense-row.expense-" + $(this).attr("data-id");
    $(hlClass).removeClass("expense-hl");
  });
}


$(document).ready(function(){
  $('.expense-button').click(function(event){
    event.preventDefault();
    var hlClass = ".expense-row.expense-" + $(this).attr("data-id");
    $(hlClass).toggleClass("expense-hl-permanent");
    return false;
  });
  $('.expense-icon').click(function(){
    var hlClass = ".expense-row.expense-" + $(this).attr("data-id");
    $(hlClass).toggleClass("expense-hl-permanent");
    return false;
  });

  hover_functions();

  $('.hide-money-checkbox').click(function(){
    $.ajax({
      method: "POST",
      url: "/hide-money",
      data: {"hide-money": this.checked}
    });
    if (this.checked) {
      $('body').addClass("hide-money");
    } else {
      $('body').removeClass("hide-money");
    };
  });

  $('.select-theme-dropdown').on('change', function(e){
    $.ajax({
      method: "POST",
      url: "/set-theme",
      data: {"theme": this.value}
    });

    $('.select-theme-dropdown option').each(function(i){
      $('body').removeClass(this.value);
    });
    $('body').addClass(this.value);
  });
});

