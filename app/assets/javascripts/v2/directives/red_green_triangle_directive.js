/*global angular, JST, $compile, unused */
/* istanbul ignore next */
angular.module('workships.directives').directive('redGreenTriangle', function () {
  'use strict';
  return {
    restrict: 'AE',
    template: JST['v2/red_green_triangle'](),
    scope: {
      trend: '=',
      rotate: '='
    },
  };
});