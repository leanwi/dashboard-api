var config = require('../config/app');
var _ = require('underscore');
var MongoClient = require('mongodb').MongoClient;
var ObjectId = require('mongodb').ObjectId;
var db;
MongoClient.connect(config.mongoUrl, function(err, database) {
  if(err) {console.log(err);}
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
  var metricInfo = parseMetricInfo(req.params.action);
  var collection = db.collection(metricInfo.collection);
  options.match.action_date = {$gte: res.locals.start, $lte: res.locals.end};
  
  if(metricInfo.metric === 'total' && req.params.code) {
    options.group = 'total';
    collection.aggregate([
      {$match: options.match},
      {$group: {_id: options.group, 'count': {$sum: 1}}},
      {$sort: {_id: 1}}
    ]).toArray(function(err, result) {
      var total = _.pluck(result, 'count')[0];
      var rank = 0;
      collection.aggregate([
        {$match: {action_date: {$gte: res.locals.start, $lte: res.locals.end}}},
        {$group: {_id: '$library_code', 'count': {$sum: 1}}},
        {$sort: {'count': -1}}
      ]).toArray(function(err, result) {
        _.find(result, function(row, index) {
          rank = index + 1;
          return row.count === total;
        });
        sendResult(['total', 'rank'], [total, rank], req, res);
      });       
    });     
  }
  else if(metricInfo.metric === 'total') {
    collection.aggregate([
      {$match: options.match},
      {$group: {_id: 'total', 'count': {$sum: 1}}},
      {$sort: {_id: 1}}
    ]).toArray(function(err, result) {
      sendResult(_.pluck(result, '_id'), _.pluck(result, 'count'), req, res);      
    });    
  }
  else {
    options.group = "$metrics." + metricInfo.metric;
    collection.aggregate([
      {$match: options.match},
      {$group: {_id: options.group, 'count': {$sum: 1}}},
      {$sort: {_id: 1}}
    ]).toArray(function(err, result) {
      sendResult(_.pluck(result, '_id'), _.pluck(result, 'count'), req, res);
    });    
  }
}

function sendResult(labels, data, req, res) {
  var metricInfo = parseMetricInfo(req.params.action);
  var responseObject = {
    url: req.url,
    collection: metricInfo.collection,
    metric: metricInfo.metric,
    code: req.params.code,
    start: req.params.start,
    end: req.params.end,
    labels: labels,
    data: data    
  };
  
  res.send(JSON.stringify(responseObject));
}

function parseMetricInfo(metricString) {
  var m = metricString.split(':');
  return {
    collection: m[0],
    metric: m[1]
  };
}

module.exports = action;