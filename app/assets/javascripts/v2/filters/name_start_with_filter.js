/*globals angular, _ */
angular.module('workships.filters').filter('nameStartWith', function () {
  'use strict';
  function hasPrefix(str, prefix) {
    str = str.trim().toLowerCase();
    return str.indexOf(prefix) === 0;
  }

  return function (data, prefix, number) {
    var start_check = number === undefined ? 2 : 3; 
    if (prefix.length < start_check) { return []; }
    prefix = prefix.trim().toLowerCase();
    var filtered = [];
    _.each(data, function (obj) {
      if (!obj) {
        return;
      }
      var list = obj.name ? obj.name.split(' ') : [];
      var done = false;
      list.push(obj.name ? obj.name : '');
      _.each(list, function (n) {
        if (!done && hasPrefix(n, prefix)) {
          filtered.push(obj);
          done = true;
        }
      });
    });
    return filtered;
  };
});
