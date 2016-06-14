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
  $('.expense-row').hover(function(){
    var hlClass = ".expense-row.expense-" + $(this).attr("data-id");
    $(hlClass).addClass("expense-hl");
  }, function() {
    var hlClass = ".expense-row.expense-" + $(this).attr("data-id");
    $(hlClass).removeClass("expense-hl");
  });
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
});

