/*globals angular, _ */
angular.module('workships-mobile.filters').filter('nameStartWith', function () {
  'use strict';
  function hasPrefix(str, prefix) {
    str = str.trim().toLowerCase();
    return str.indexOf(prefix) === 0;
  }

  return function (data, prefix) {
    if (prefix.length < 2) { return []; }
    prefix = prefix.trim().toLowerCase();
    var filtered = [];
    _.each(data, function (obj) {
      if (!obj) {
        return;
      }
      var list = obj.name.split(' ');
      var done = false;
      list.push(obj.name);
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
