var app = require('express').createServer();

/* Handles HTTP Requests. It's crude, I know. */
app.get('/', function(req, res){
    res.send('This is the Nitro API. Undocumented because I\'m lazy.');
});

//Initial Auth
app.get('/auth/', function(req, res){
    res.send('Don\'t know how auth works, so put in your own variables');
});

//Timestamps Only
app.get('/update/', function(req, res){
    res.send('token: ' + req.query["token"] + '<br>timestamp: ' + req.query["timestamp"]);
});

//Actual Sync
app.get('/sync/', function(req, res){
    res.send('token: ' + req.query["token"] + '<br>data: ' + req.query["data"]);
});

app.listen(3000);
