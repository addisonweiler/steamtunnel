//# Change text when favorite link clicked on
$(document).ready(function(){bindEvents(),$("p.notice, p.alert").delay(500).fadeIn("normal",function(){$(this).delay(2500).fadeOut()}),$("#date_selected").change(postDateSelection)}),bindEvents=function(){$(".favorite, .unfavorite").bind("click",toggleFavorite),$(".event").children(".info").show(),$(".event").children(".description").show()},toggleFavorite=function(a){if($(a.target).is("a")){var b=a.target.innerHTML=="Favorite"?"Unfavorite":"Favorite";a.target.innerHTML=b,a.target.className=a.target.className.replace(/(?:^|\s)favorite(?!\S)/,b.toLowerCase())}},postDateSelection=function(){elem=$(this).children(":selected");var a=$(elem).text(),b={date:a},c="/events/stumble";console.log("path"),$.ajax({url:c+"?date="+a,type:"get",dataType:"script",success:bindEvents})}