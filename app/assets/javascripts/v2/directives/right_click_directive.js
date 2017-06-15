/*global angular, JST, unused */
angular.module('workships.directives').directive('ngRightClick', function ($parse) {
  'use strict';
  return function (scope, elem, attrs) {
    var fn = $parse(attrs.ngRightClick);
    elem.bind('contextmenu', function (event) {
      scope.$apply(function () {
        event.preventDefault();
        fn(scope, {$event: event});
      });
    });
  };
});