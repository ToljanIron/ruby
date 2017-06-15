/*global angular, console, JST, unused */

angular.module('workships.directives').directive('addTopToAnalyzeSidebarCriteria', function ($window) {
  'use strict';
  return {
    restrict: 'A',

    link: function (scope, elem, attrs) {
      var e = elem[0];

      var on_scroll = function () {
        var scrolled = $window.document.body.scrollTop;
        e.style.top = (scrolled + parseInt(attrs.top, 10)).toString() + 'px';
      };
      scope.$on('scroll', on_scroll);
    }
  };
});
