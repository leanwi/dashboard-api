var excel = require('excel-export');
var _ = require('underscore');

var util = {
  toExcel: function(req, res) {
    var chart = JSON.parse(req.body.chart);
    var conf = {};
    conf.rows = _.map(chart.data.labels, function(label, index) {
      return _.flatten([label, _.map(chart.data.data, function(col){return col[index];})]);
    });
    
    if(chart.data.series.length > 1) {
      conf.cols = [{caption: '', type: 'string'}].concat(_.map(chart.data.series, function(col) {
        return {caption: col, type: 'number'};
      }));
    }
    else {
      conf.cols = [{caption:'Labels', type: 'string'},{caption:'Values', type: 'number'}];
    }
    
    res.setHeader('Content-disposition', 'attachment; filename=' + chart.options.title + '.xlsx');
    res.setHeader('Content-type', 'application/vnd.openxlmformats');
    res.end(excel.execute(conf), 'binary');
    // res.send('ok');
  }
}

module.exports = util;