function strip(e){var t=document.createElement("DIV");return t.innerHTML=e,t.textContent||t.innerText||""}function getSelectedDates(e,t){e+="_tag";for(var r="",a=["Lectures","Performances","Career","Politics","Tech","Parties","Sports","User-created","Food"],n=[1,2,3,4,5,6,7,10,11],i=0;i<a.length;i++){var s=a[i];e==s+"_tag"?t&&(r+="&selected_filters%5B%5D="+n[i]):$(document.getElementById(a[i]+"_tag").children[0]).hasClass("active")&&(r+="&selected_filters%5B%5D="+n[i])}return r}function getSearchTerm(){var e=document.getElementById("search-input").value;return""==e?"":"&search_term="+e}function getDatesForSearch(){for(var e="",t=["Lectures","Performances","Career","Politics","Tech","Parties","Sports","User-created","Food"],r=[1,2,3,4,5,6,7,10,11],a=0;a<t.length;a++)e+="&selected_filters%5B%5D="+r[a];return e}$(document).ready(function(){bindEvents(),$("p.notice, p.alert").delay(500).fadeIn("normal",function(){$(this).delay(2500).fadeOut()}),$("#date_selected").change(postFilterSelection),$("#search-input").change(postSearchResults),postFilterSelection()}),bindEvents=function(){$(".favorite, .unfavorite").bind("click",toggleFavorite),$(".event").bind("click",fillDetails)},fillDetails=function(e){if(!$(e.target).is(".favorite")&&!$(e.target).is(".unfavorite")){var t=this.children[0].getElementsByTagName("td")[1].innerHTML;$("#detailsTitle").html(t);var r=this.children[0].getElementsByTagName("td")[2].innerHTML;r=strip(r),$("#detailsDate").html(r);var a=this.children[0].getElementsByTagName("td")[3].innerHTML;$("#detailsLocation").html(a);var n=this.children[1].innerHTML;$("#detailsDescription").html(n);var i=$(this).children(".info").html();$("#detailsInfo").html(i);var s=this.children[0].getElementsByTagName("td")[4].children[0].innerHTML;s=strip(s),$("#detailsGroup").text(s),$("#detailsLinks > a").click(toggleFavorite)}},toggleFavorite=function(e){if($(e.target).is("a")){var t="Favorite"==e.target.innerHTML?"Unfavorite":"Favorite";e.target.innerHTML=t,e.target.className=e.target.className.replace(/(?:^|\s)favorite(?!\S)/,t.toLowerCase())}},buttonPressed=function(){var e=-1==event.target.className.indexOf("active"),t=$(event.target).text();postFilterSelection(t,e)},postFilterSelection=function(e,t){elem=document.getElementById("date_selected");var r=$(elem).val();console.log(r);var a="/events?date="+r+getSelectedDates(e,t)+getSearchTerm();console.log(a),$.ajax({url:a,type:"get",dataType:"script",success:bindEvents})},postSearchResults=function(){var e="/events?date=This Month"+getDatesForSearch()+getSearchTerm();console.log(e),$.ajax({url:e,type:"get",dataType:"script",success:bindEvents})};