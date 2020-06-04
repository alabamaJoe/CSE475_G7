// This is the server-side JS code to read the html file and display on port 8080 of the local host
var fs = require('fs');
var http = require('http');

const PORT=8080;
 

fs.readFile('./index.html', function (err, html) {

    if (err) throw err;    

    http.createServer(function(request, response) {  
        response.writeHeader(200, {"Content-Type": "text/html"});  
        response.write(html);  
        response.end();  
    }).listen(PORT);
});