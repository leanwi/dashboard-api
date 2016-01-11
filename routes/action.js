var config = require('../config/app');
var _ = require('underscore');
var MongoClient = require('mongodb').MongoClient;
var ObjectId = require('mongodb').ObjectId;
var db;
MongoClient.connect(config.mongoUrl, function(err, database) {
  db = database;
});

var action = {
  getAll: function(req, res) {
    var options = {match: {}};
    getMetric(options, req, res);
  },
  getLibrary: function(req, res) {
    var options = {match: {library_code: {$in: req.params.code.split(',')}}};
    getMetric(options, req, res);
  }
}

function getMetric(options, req, res) {
  var metricInfo = req.params.action.split(':');
  var collection = db.collection(metricInfo[0]);
  if(metricInfo[1] === 'total') {
    options.group = 'total';
  }
  else {
    options.group = "$metrics." + metricInfo[1];
  }
  options.match.action_date = {$gte: res.locals.start, $lte: res.locals.end};

  collection.aggregate([
    {$match: options.match},
    {$group: {_id: options.group, 'count': {$sum: 1}}},
    {$sort: {_id: 1}}
  ]).toArray(function(err, result) {
    var responseObject = {
      url: req.url,
      collection: metricInfo[0],
      metric: metricInfo[1],
      code: req.params.code,
      start: req.params.start,
      end: req.params.end,
      labels: _.pluck(result, '_id'),
      data: _.pluck(result, 'count')
    };

    res.send(JSON.stringify(responseObject));
  });
}

module.exports = action;