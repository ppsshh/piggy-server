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
});

