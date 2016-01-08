var mongo = require('mongodb').MongoClient;
var ObjectId = require('mongodb').ObjectId;
var prompt = require('prompt');
var bcrypt = require('bcrypt-nodejs');
var config = require('./config/app');

var schema = {
  properties: {
    username: {
      description: 'Dashboard administrator username',
      required: true,
    },
    password: {
      description: 'Dashboard administrator password',
      required: true,
      hidden: true,
    },
    email: {
      description: 'Dashboard administrator email address',
      required: true,
    }       
  }
}

prompt.message = 'Dashboard';
prompt.start();

prompt.get(schema, function(err, result) {
  if(err) {console.log(err);}
  addUser(result);
});

function addUser(answers) {
  console.log('Adding the default user to the database');
  
  mongo.connect(config.mongoUrl, function(err, db) {
    if(err) {
      console.log('MongoDB error: ' + err);
    }
    else {
      db.ensureIndex('users', {name: 1}, {unique: true, background:true, w:1}, function(err, index) {
        db.collection('users').insertOne({
          name: answers.username,
          password: bcrypt.hashSync(answers.password),
          email: answers.email,
          role: 'admin'
        }, function(err, r) {
          if(err) {
            console.log('There was an error and the user was not added. [' + err + ']');
          }
          else {
            console.log('One user added.');
          }
          db.close();
        });        
      });  
    }
  });
}