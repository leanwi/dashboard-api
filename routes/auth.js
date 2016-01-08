var jwt = require('jwt-simple');
var config = require('../config/app');
var MongoClient = require('mongodb').MongoClient;
var ObjectId = require('mongodb').ObjectId;
var bcrypt = require('bcrypt-nodejs');
var db;

MongoClient.connect(config.mongoUrl, function(err, database) {
  db = database;
});
 
var auth = {
  login: function(req, res) {
 
    var username = req.body.username || '';
    var password = req.body.password || '';
 
    if (username == '' || password == '') {
      res.status(401);
      res.json({
        "status": 401,
        "message": "Invalid credentials"
      });
      return;
    }
 
    var dbUserObj = auth.validate(username, password, function(dbUserObj) {
      if (!dbUserObj) { // If authentication fails, we send a 401 back
        res.status(401);
        res.json({
          "status": 401,
          "message": "Invalid credentials"
        });
        return;
      }
 
      if (dbUserObj) {
        res.json(genToken(dbUserObj));
      }
        
    });
  },
 
  validate: function(username, password, callback) {
    var dbUserObj;
    db.collection('users').findOne({name: username}, function(err, user) {
      if(err) {
        console.log(err);
      }
      else {
        var hash = user.password;
        if(bcrypt.compareSync(password, hash)) {
          dbUserObj = {
            username: username,
            role: user.role,
            email: user.email,
          };
        }
        callback(dbUserObj);          
      }        
    });
  },
 
  validateUser: function(username, callback) {
    var dbUserObj;
    db.collection('users').findOne({name: username}, function(err, user) {
      if(err) {
        console.log(err);
      }
      else if(user) {
        dbUserObj = {
          username: username,
          role: user.role,
          email: user.email,
        };
      }
      callback(dbUserObj);
    });
  },
}
 
// private method
function genToken(user) {
  var expires = expiresIn(7); // 7 days
  var token = jwt.encode({
    exp: expires
  }, require('../config/secret')());
 
  return {
    token: token,
    expires: expires,
    user: user
  };
}
 
function expiresIn(numDays) {
  var dateObj = new Date();
  return dateObj.setDate(dateObj.getDate() + numDays);
}
 
module.exports = auth;
