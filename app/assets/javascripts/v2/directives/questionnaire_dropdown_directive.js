/*globals angular, JST */
angular.module('workships.directives').directive('dropdownWithTitle', function () {
  'use strict';
  return {
    replace: true,
    scope: {
      title: '@',
      options: '=',
      hideArrow: '=',
      onOpen: '&'
    },
    template: JST['v2/questionnaire_dropdown_directive'](),
    link: function (scope) {
      scope.toggle = function () {
        scope.open = !scope.open;
      };
      scope.close = function () {
        if (scope.open) {
          scope.toggle();
        }
      };
    }
  };
});