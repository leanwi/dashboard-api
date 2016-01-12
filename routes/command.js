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

var command = {
  upload: function(req, res) {
    var uploadSuccesses = 0;

    if(req.body) {
      var recordType = req.body.type;
      startJob(recordType, startUpload);
    }
    res.end('');

    function startUpload(jobId) {
      var collection = db.collection(recordType);
      insert(req.body.rows);

      function insert(values) {
        if(values.length > 0) {
          var tmpValues = _.map(_.first(values, 1000), function(value) {
            value.job_id = jobId;
            value.action_date = moment(value.action_date, 'YYYY-MM-DD HH:mm:ss').toDate();
            return value;
          });
          collection.insertMany(tmpValues, function(err, result) {
            if(err) {
              console.log(err);
              finish(JOB_ERROR);
            }
            else {
              uploadSuccesses += result.insertedCount;
              updateJob(jobId, JOB_ACTIVE, uploadSuccesses);
              insert(_.rest(values, 1000));
            }
          });
        }
        else {
          finish(JOB_COMPLETE);
        }
      }

      function finish(state) {
        updateJob(jobId, state, uploadSuccesses);
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