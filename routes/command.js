var config = require('../config/app');
var _ = require('underscore');
var moment = require('moment');
var MongoClient = require('mongodb').MongoClient;
var ObjectId = require('mongodb').ObjectId;
var db;
MongoClient.connect(config.mongoUrl, function(err, database) {
  db = database;
});

var JOB_ACTIVE = "Active";
var JOB_ERROR = "Error";
var JOB_COMPLETE = "Complete";
var CHUNK_SIZE = 1000;
var DATE_FORMAT = 'YYYY-MM-DD HH:mm:ss';

var command = {
  upload: function(req, res) {
    var uploadSuccesses = 0;

    if(req.body) {
      var recordType = req.body.type;
      startJob(recordType, startUpload);
      db.collection(recordType).createIndex({action_date: -1, library_code: 1}, {background: true});
    }
    res.end('');

    function startUpload(jobId) {
      var collection = db.collection(recordType);
      insert(req.body.rows);

      function insert(values) {
        var tmpValues = _.map(_.first(values, CHUNK_SIZE), function(value) {
          value.job_id = jobId;
          value.action_date = moment(value.action_date, DATE_FORMAT).toDate();
          return value;
        });
        collection.insertMany(tmpValues, function(err, result) {
          if(err) {
            console.log(err);
            updateJob(jobId, JOB_ERROR, uploadSuccesses);
          }
          else {
            uploadSuccesses += result.insertedCount;
            if(_.rest(values, CHUNK_SIZE).length > 0) {
              updateJob(jobId, JOB_ACTIVE, uploadSuccesses);
              insert(_.rest(values, CHUNK_SIZE));
            }
            else {
              updateJob(jobId, JOB_COMPLETE, uploadSuccesses);
            }
          }
        });
      }
    }
  },
}

function startJob(type, callback) {
  db.collection('jobs').insertOne({
    type: type,
    start: new Date(),
    updated: new Date(),
    state: JOB_ACTIVE,
    processed: 0
  }, function(err, result) {
    if(err) {
      console.log(err);
    }
    else {
      callback(result.insertedId);
    }
  });
}

function updateJob(id, state, processed) {
  db.collection('jobs').updateOne({_id: id}, {$set: {
    updated: new Date(),
    state: state,
    processed: processed
  }});
}

module.exports = command;