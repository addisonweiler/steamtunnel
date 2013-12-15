$(document).ready( function() {
  $('.unfavorite').bind('click', function () {
    $(this).parent().parent().parent().hide() // TODO better way of selecting event box?
  })
});