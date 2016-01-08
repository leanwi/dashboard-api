var moment = require('moment');

module.exports = function(req, res, next) {
  if(req.params.start) {
    res.locals.start = moment(req.params.start, 'MM-DD-YYYY').startOf('day').format('YYYY-MM-DD HH:mm:ss');
  }
  if(req.params.end) {
    res.locals.end = moment(req.params.end, 'MM-DD-YYYY').endOf('day').format('YYYY-MM-DD HH:mm:ss');
  }

  next();
}
