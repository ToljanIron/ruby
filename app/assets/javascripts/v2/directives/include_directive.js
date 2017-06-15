/*global angular, unused, JST */

angular.module('workships.directives').directive('includeDirective', function () {
  'use strict';
  return {
    restrict: 'AE',
    replace: true,
    template: function (el, attrs) {
      angular.noop(el);
      return JST[attrs.template]();
    },
    link : function (scope, el, attrs) {
      angular.noop(el);
      scope.ctrlr = attrs.ctrlr;
    }
  };
});