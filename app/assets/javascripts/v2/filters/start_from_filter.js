/*globals angular, console, unused, _ */
angular.module('workships.filters').filter('startFrom', function () {
  'use strict';
  return function (input, start) {
    if (!input) { return; }
    start = +start; //parse to int
    return input.slice(start);
  };
});