/*global angular, JST, unused, $window */
angular.module('workships.directives').directive('miniHeader', function ($window, tabService) {
  'use strict';
  return {
    restrict: 'E',
    template: JST['v2/mini_header_tab'](),
    scope: {
      atab: "=",
    },
    link: function (scope) {
      scope.tabService = tabService;
      angular.element($window).bind('scroll', function () {
        scope.$apply();
        if (this.pageYOffset >= 50) {
          tabService.showMiniHeader = true;
        } else {
          tabService.showMiniHeader = false;
        }
      });
    }
  };
});
