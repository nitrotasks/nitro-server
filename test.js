var OAuth = require("oauth").OAuth,
	express = require("express").createServer();

var oa = new OAuth("https://one.ubuntu.com/oauth/request/",
					 "https://one.ubuntu.com/oauth/access/",
					 "ubuntuone",
					 "hammertime",
					 "1.0",
					 "http://localhost:3000",
					 "PLAINTEXT")

// var request = {
// 	token: "",
// 	secret: ""
// }

var access = {
	token: "p05x2WVPTGj15J8vT9K3",
	secret: "l9KjpNXfb73vf6qJKthqm3hgpwh0fDMcT2n1FcTN0D8CLx5kmHtbWC4nvxzmJhZjDnk8L6872vSXDR7Z"
}

oa.get("https://files.one.ubuntu.com/content/~/Ubuntu%20One/Nitro/super.json", access.token, access.secret, function (e, d, r) {
	console.log(e ? e :  d);
});

// oa.getOAuthRequestToken(function(error, oauth_token, oauth_token_secret,  results){

// 	if (error) return console.log('error :' + JSON.stringify(error))

// 	request.token = oauth_token;
// 	request.secret = oauth_token_secret

// 	console.log('https://one.ubuntu.com/oauth/authorize/?oauth_token=' + oauth_token);
// });

// express.get('/', function (req, res) {
// 	res.send("Hello World :D");
// 	console.log("Requesting access token")
// 	oa.getOAuthAccessToken(request.token, request.secret, req.query.oauth_verifier, function(error, oauth_access_token, oauth_access_token_secret, results) {
// 		console.log('oauth_access_token :' + oauth_access_token)
// 		console.log('oauth_token_secret :' + oauth_access_token_secret)
// 		console.log("Requesting account details")
// 		var data= "";
// 		oa.getProtectedResource("https://one.ubuntu.com/api/file_storage/v1", "GET", oauth_access_token, oauth_access_token_secret, function (error, data, response) {
// 			console.log(data);
// 		});
// 	});
// });

// express.listen(3000)
