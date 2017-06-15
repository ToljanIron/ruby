/*global angular, JST, $compile, unused */
/* istanbul ignore next */
angular.module('workships.directives').directive('bars', function () {
  'use strict';
  return {
    restrict: 'E',
    transclude: true,
    template: JST["v2/bars"](),
    scope: {
      employeesByAttributes: '=',
      empIndex: '=',
    },
  };
});
