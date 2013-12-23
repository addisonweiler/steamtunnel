// This is a manifest file that'll be compiled into including all the files listed below.
// Add new JavaScript/Coffee code in separate files in this directory and they'll automatically
// be included in the compiled file accessible from http://example.com/assets/application.js
// It's not advisable to add code directly here, but if you do, it'll appear at the bottom of the
// the compiled file.
//Popover
$(document).ready(function() {
    $("[rel='popover']").popover({
        placement : 'bottom', // top, bottom, left or right
        html: 'true',
        content : "<div id=\"sign_in_popover\">\n  <table id=\"popup\">\n    <form accept-charset=\"UTF-8\" action=\"/users/sign_in\" method=\"post\"><div style=\"margin:0;padding:0;display:inline\"><input name=\"utf8\" type=\"hidden\" value=\"&#x2713;\" /><input name=\"authenticity_token\" type=\"hidden\" value=\"A73ZvhUZ6GOwBy9RBrsG4T/TdTvhNRkfym6AzTeOr0M=\" /><\/div>\n        <tr>\n          <td> <b> Username: <\/b> <\/td> <td> <input id=\"user_email\" name=\"user[email]\" size=\"30\" type=\"text\" /> <\/td>\n        <\/tr>\n        <tr>\n          <td> <b> Password: <\/b> <\/td> <td> <input id=\"user_password\" name=\"user[password]\" size=\"30\" type=\"password\" /> <\/td>\n        <\/tr>\n        <tr>\n          <td> <input name=\"commit\" type=\"submit\" value=\"Sign in\" /> <\/td>\n          <td colspan=\"2\"> <label for=\"user_remember_me\">Remember me<\/label> &nbsp; <input name=\"user[remember_me]\" type=\"hidden\" value=\"0\" /><input id=\"user_remember_me\" name=\"user[remember_me]\" type=\"checkbox\" value=\"1\" /> <\/td>\n\n        <\/tr>\n        <tr>\n\n          <td> <form method=\"get\" action=\"/users/sign_up\"  class=\"button_to\"><div><input id=\"sign_up\" type=\"submit\" value=\"Sign up\" /><\/div><\/form><\/td>\n\n        <\/tr>\n\n        <tr>\n          <td colspan=\"2\"> <a href=\"/users/password/new\">Forgot your password?<\/a> <\/td>\n        <\/tr>\n        <tr>\n          <td colspan=\"2\"><a href=\"/users/confirmation/new\" id=\"confirmation\">No confirmation?<\/a><\/td>\n<\/form>    <\/tr>\n  <\/table>\n<\/div>"
    });
});