$(document).ready(function(){
  $('.expense-button').click(function(event){
    event.preventDefault();
    var myClass = $(this).attr("data-name");
    $('#expenses-table').toggleClass(myClass);
    return false;
  });
});

