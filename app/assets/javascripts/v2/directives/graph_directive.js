/*global angular, JST, $compile, unused */
/* istanbul ignore next */
angular.module('workships.directives').directive('graphDirective', function () {
  'use strict';
  return {
    restrict: 'E',
    template: JST.graph(),
  };
});
