var OAuth2 = require("oauth").OAuth2,
	express = require("express").createServer();

var scopes = "https://www.googleapis.com/auth/drive.file https://www.googleapis.com/auth/userinfo.email https://www.googleapis.com/auth/userinfo.profile";

var oa = new OAuth2("208808167997.apps.googleusercontent.com", "bWYNj1RjRYagGHHrStugd1Ps", "https://www.googleapis.com", "/auth/drive", "/auth/drive")

oa.getOAuthAccessToken("", {scope: scopes, redirect_uri: "https://stark-fog-5496.herokuapp.com/googledrive"}, function(error, access_token, refresh_token, results) {
	console.log(error, access_token, refresh_token, results);
})