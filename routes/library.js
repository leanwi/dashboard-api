var config = require('../config/app');
var MongoClient = require('mongodb').MongoClient;
var ObjectId = require('mongodb').ObjectId;
var db;
MongoClient.connect(config.mongoUrl, function(err, database) {
  db = database;
});

var library = {
  getAll: function(req, res) {
    db.collection('libraries').find({}).toArray(function(err, results) {
      if(err) {
        console.log(err);
        res.status(500).send('There was an error');
      }
      else {
        res.send(results);
      }        
    });
  },
  getOne: function(req, res) {
    db.collection('libraries').findOne({code: req.params.code}, function(err, result) {
      if(err) {
        console.log(err);
        res.status(500).send('There was an error');
      }
      else {
        res.send(result);
      }        
    });    
  },
}

module.exports = library;
