/*global angular, JST, unused */

angular.module('workships.directives').directive('autoFocus', function ($timeout) {
  'use strict';
  return {
    link: function (scope, element) {
      scope.$watch('focusTriger', function (value) {
        if (value === true) {
          $timeout(function () {
            element[0].focus();
          });
        }
      });
    }
  };
});
