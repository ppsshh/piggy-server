$(document).ready(function(){
  var fixedHighlight = function(expenseType){
    expenseType = expenseType + "-fixed";
    $('#expenses-table').toggleClass(expenseType);
    return false;
  };
  $('.expense-button').click(function(event){
    event.preventDefault();
    fixedHighlight( $(this).attr("data-name") );
  });
  $('.expense-row').click(function(){
    fixedHighlight( $(this).attr("data-name") );
  });
  $('.expense-row').hover(function(){
    var myClass = $(this).attr("data-name");
    $('#expenses-table').addClass(myClass);
  }, function() {
    var myClass = $(this).attr("data-name");
    $('#expenses-table').removeClass(myClass);
  });
});

