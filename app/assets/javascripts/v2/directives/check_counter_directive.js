/*globals angular */

angular.module('workships.directives').directive('checkCount', function () {
  'use strict';
  return {
    restrict: 'E',
    scope: {
      count: '@'
    },
    template: "<div ng-show='count > 0' class='count-circle'>{{count}}</div>"
  };
});