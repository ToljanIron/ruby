/*globals angular */
angular.module('workships.filters').filter('arrayRangeFilter', function () {
  'use strict';
  return function (data, range) {
    var filtered = [];
    if (!data) {
      return filtered;
    }
    var i;
    for (i = 0; i < data.length; i++) {
      /* istanbul ignore else */
      if (range !== undefined) {
        if (i >= range[0] && i <= range[1]) {
          filtered.push(data[i]);
        }
      }
    }
    return filtered;
  };
});
