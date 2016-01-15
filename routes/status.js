var config = require('../config/app');
var _ = require('underscore');
var moment = require('moment');
var MongoClient = require('mongodb').MongoClient;
var db;
var ObjectId = require('mongodb').ObjectId;

MongoClient.connect(config.mongoUrl, function(err, database) {
  db = database;
});

var status = {
  getAllJobs: function(req, res) {
    db.collection('jobs').find().sort({start: -1}).toArray(function(err, results) {
      if(err) {
        console.log(err);
        res.status(500).send('There was an error');
      }
      else {
        res.send(results);
      }        
    });
  },
  getActiveJobs: function(req, res) {
    db.collection('jobs').find({state: "Active"}).sort({start: -1}).toArray(function(err, results) {
      if(err) {
        console.log(err);
        res.status(500).send('There was an error');
      }
      else {
        res.send(results);
      }        
    });
  },
  getFailedJobs: function(req, res) {
    db.collection('jobs').find({state: "Error"}).sort({start: -1}).toArray(function(err, results) {
      if(err) {
        console.log(err);
        res.status(500).send('There was an error');
      }
      else {
        res.send(results);
      }        
    });
  },
  getRecentJobs: function(req, res) {
    console.log(req.params.last);
    db.collection('jobs').find().sort({start: -1}).limit(parseInt(req.params.last) || 1000).toArray(function(err, results) {
      if(err) {
        console.log(err);
        res.status(500).send('There was an error');
      }
      else {
        res.send(results);
      }         
    });
  },
  getOneActionMetricType: function(req, res) {
    db.collection(req.params.type).aggregate([
      {$group: {_id: '', maxID: {$max: "$original_id"}, maxDate: {$max: "$action_date"}}}
    ]).toArray(function(err, result) {
      res.send(result[0] || {});
    });
  },
}

module.exports = status;