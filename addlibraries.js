var mongo = require('mongodb').MongoClient;
var ObjectId = require('mongodb').ObjectId;
var config = require('./config/app');
var prompt = require('prompt');
var csv = require('csv');
var fs = require('fs');
var _ = require('underscore');

var schema = {
  properties: {
    librariesFile: {
      description: 'Where is the csv file with library information?',
      default: 'libraries.csv',
      required: true,
    }           
  }
}

prompt.message = 'Dashboard';
prompt.start();

prompt.get(schema, function(err, result) {
  if(err) {console.log(err);}
  getCsv(result.librariesFile);
});

function getCsv(fileName) {
  var text = fs.readFileSync(fileName);
  if(text === '') {
    console.log('The file was empty, not found or you don\'t have permission to read it.');
    return;
  }
  else {
    parseCsv(text);    
  }
}

function parseCsv(data) {
  csv.parse(data, {}, function(err, output) {
    if(err) {
      console.log(err); 
    }
    else {
      addLibraries(output);
    }
  })
}

function addLibraries(libraryArray) {
  console.log('Adding the library list to the database.');
  
  var libraries = _.map(libraryArray.slice(1), function(row) {
    return {
      name: row[0],
      code: row[1]
    };
  });
  
  mongo.connect(config.mongoUrl, function(err, db) {
    if(err) {
      console.log('MongoDB error: ' + err);
    }
    else {
      db.collection('libraries').drop(function() {
        db.collection('libraries').insertMany(libraries, function(err) {
          if(err) {console.log('MongoDB error: ' + err);}
          db.close();    
        }); 
      });
    }
  });
}