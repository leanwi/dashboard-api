var express = require('express');
var router = express.Router();
 
var auth = require('./auth.js');
var action = require('./action.js');
var library = require('./library.js');
var command = require('./command.js');
var status = require('./status.js');
var util = require('./util.js');
 
/*
 * Routes that can be accessed by anyone
 */
router.post('/api/v1/login', auth.login);
router.get('/api/v1/libraries', library.getAll);
router.get('/api/v1/libraries/:code', library.getOne);
router.get('/api/v1/actions/:action/:start/:end', action.getAll); 
router.get('/api/v1/actions/:action/:start/:end/:code', action.getLibrary); 
router.post('/api/v1/util/charttoexcel', util.toExcel); 

/*
 * Routes that can be accessed only by autheticated users
 */
router.get('/api/v1/status/jobs', status.getAllJobs);
router.get('/api/v1/status/jobs/active', status.getActiveJobs);
router.get('/api/v1/status/jobs/failed/:last?', status.getFailedJobs);
router.get('/api/v1/status/jobs/recent/:last?', status.getRecentJobs);
router.get('/api/v1/status/action-metric-types/:type', status.getOneActionMetricType);
router.post('/api/v1/commands/upload', command.upload);
 
module.exports = router;
