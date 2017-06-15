/*globals angular */

angular.module('workships.directives').directive('scrollingPanel', function ($window) {
  'use strict';

  return {
    transclude: true,
    replace: true,
    scope: {
      reduce: '@',
      min: '@'
    },
    template: "<div id='scroller' ng-transclude></div>",
    link: function (scope, element) {
      if (!scope.reduce) { scope.reduce = '162'; }
      var prefix = scope.min ? 'min-' : '';
      element.css(prefix + 'height', ($window.innerHeight - parseInt(scope.reduce, 10)) + 'px');
    }
  };

});