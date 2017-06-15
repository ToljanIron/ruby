/*global angular, JST, $compile, unused */
/* istanbul ignore next */
angular.module('workships.directives').directive('graphHeader', function () {
  'use strict';
  return {
    restrict: 'AE',
    template: JST['v2/graph_header'](),
  };
});
