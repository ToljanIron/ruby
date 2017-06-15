/*global angular, JST, $compile, unused */
angular.module('workships.directives').directive('windowSize', function ($window) {
  'use strict';
  return {
    restrict: 'E',
    scope: {
      screenSize: "="
    },
    link: function postLink(scope) {
      angular.element($window).bind('resize', function () {
        scope.$apply();
        scope.screenSize = {
          height: $window.innerHeight,
          width:  $window.innerWidth
        };
      });
    }
  };
});
