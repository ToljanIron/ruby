/*global angular, JST, $compile, unused */
angular.module('workships.directives').directive('pageUnavailable', function () {
  'use strict';
  return {
    restrict: 'E',
    template: JST['v2/page_unavailable'](),
    scope: {

    },
    controller: function ($scope) {
      $scope.goToWebsite = function () {
        
      };
    },
  };
});