var moment = require('moment');

module.exports = function(req, res, next) {
  if(req.params.start) {
    res.locals.start = moment(req.params.start, 'MM-DD-YYYY').startOf('day').toDate();
  }
  if(req.params.end) {
    res.locals.end = moment(req.params.end, 'MM-DD-YYYY').endOf('day').toDate();
  }

  next();
}
