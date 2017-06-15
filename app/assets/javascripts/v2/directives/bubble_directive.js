/*global angular, JST, $compile, unused */
angular.module('workships.directives').directive('bubble', function (utilService) {
  'use strict';
  return {
    restrict: 'E',
    template: JST['v2/bubble'](),
    scope: {
      index: '=',
      content: '=',
    },
    controller: function ($scope) {
      $scope.bubble = utilService.getPositionToBubble();
    },
  };
});