var cluster = require('cluster');
var config = require('./config/app');
 
if(cluster.isMaster) {
  var cpuCount = require('os').cpus().length;

  for (var i = 0; i < cpuCount; i += 1) {
    cluster.fork();
  }
}
else {
  var express = require('express');
  var path = require('path');
  var logger = require('morgan');
  var bodyParser = require('body-parser');
  var app = express();
   
  app.use(logger('dev'));
  app.use(bodyParser.json({limit: '500mb'}));
   
  app.all('/*', function(req, res, next) {
    // CORS headers
    res.header("Access-Control-Allow-Origin", "*"); // restrict it to the required domain
    res.header('Access-Control-Allow-Methods', 'GET,PUT,POST,DELETE,OPTIONS');
    // Set custom headers for CORS
    res.header('Access-Control-Allow-Headers', 'Content-type,Accept,X-Access-Token,X-Key');
    if (req.method == 'OPTIONS') {
      res.status(200).end();
    } else {
      next();
    }
  });
   
  // Auth Middleware - This will check if the token is valid
  // Only the requests that start with /api/v1/* will be checked for the token.
  // Any URL's that do not follow the below pattern should be avoided unless you 
  // are sure that authentication is not needed
  app.all('/api/v1/commands/*', [require('./middlewares/validateRequest')]);
  app.all('/api/v1/status/*', [require('./middlewares/validateRequest')]);

  // Fix date middleware. Normalizes the date in the url to the format we want
  app.all('/api/v1/actions/:action/:start/:end*', [require('./middlewares/fixDates')]);
   
  app.use('/', require('./routes'));
   
  // If no route is matched by now, it must be a 404
  app.use(function(req, res) {
    res.status(404).send("Not Found");
  });
   
  // Start the server
  app.set('port', config.port);
   
  var server = app.listen(app.get('port'), function() {
    console.log('Express server listening on port ' + server.address().port);
  });
}
