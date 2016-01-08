var fs = require("fs");
var prompt = require("prompt");
var configLocation = "config/app.js";
var secretLocation = "config/secret.js";

var schema = {
  properties: {
    port: {
      description: "What port should the API run on?",
      default: 3000,
      type: "number",
      message: "Must be a number",
      required: true
    },   
    mongoHost: {
      description: "MongoDB server fqdn or ip address",
      default: "127.0.0.1",
      required: true,
    },
    mongoPort: {
      description: "MongoDB server port",
      default: "27017",
      required: true,
      type: "string",
    },
    mongoDatabase: {
      description: "MongoDB server database name",
      default: "dashboard",
      required: true,
    },
    mongoUser: {
      description: "MongoDB server username - optional",
      required: false,
    },
    mongoPassword: {
      description: "MongoDB server password - optional",
      hidden: true,
      required: false,
    },
    serverSecret: {
      description: "Please enter a secret string - used for authentication",
      required: true,
    }   
  }
}

prompt.message = "Dashboard";
prompt.start();

prompt.get(schema, function(err, result) {
  if(err) {console.log(err);}
  writeConfigFile(result);
});

function writeConfigFile(answers) {
  console.log("Writing the config and secret files.");
  
  var configStream = fs.createWriteStream(configLocation, {defaultEncoding: "utf8"});
  if(!configStream) {console.log("Could not create the config file."); return;}
  configStream.write("var config = {\n");
  configStream.write("  port: " + answers.port + ",\n");
  configStream.write("  mongoUrl: '" + createMongoUrl(answers) + "'\n");
  configStream.write("};\n");
  configStream.write("module.exports = config;\n");
  configStream.end();
  
  var secretStream = fs.createWriteStream(secretLocation, {defaultEncoding: "utf8"});
  if(!secretStream) {console.log("Could not create the secret file."); return;}
  secretStream.write("module.exports = function() {\n");
  secretStream.write("  return '" + answers.serverSecret + "';\n");
  secretStream.write("}\n");
  secretStream.end();  
  
  console.log("The config files have been created.");
}

function createMongoUrl(answers) {
  var userstring = '';
  if(answers.mongoUser != '') {
    userstring = answers.mongoUser + ":" + answers.mongoPassword + "@";
  }
  return "mongodb://" + userstring + answers.mongoHost + ":" + answers.mongoPort + "/" + answers.mongoDatabase;  
}
