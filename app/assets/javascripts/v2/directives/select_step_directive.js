/*global angular, JST, unused, $window , document*/
angular.module('workships.directives').directive('selectStep', function (tabService) {
  'use strict';
  return {
    restrict: 'E',
    template: JST['v2/select_step'](),
    scope: {
      list: '=',
      selected: '=',
      displayKey: '=',
      onClickFunc: '='
    },
    link: function (scope) {
      scope.tabService = tabService;
      scope.update_selected = function (item) {
        scope.selected = item;
        scope.onClickFunc(item);
      };
    }
  };
});