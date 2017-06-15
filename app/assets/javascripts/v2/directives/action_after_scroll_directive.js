/*global angular, JST, unused */

angular.module('workships.directives').directive('actionAfterScroll', function ($window) {
  'use strict';
  return {
    restrict: 'A',
    link: function (scope, elem, attrs) {
      var e = elem[0];
      var orig_top = e.style.top;

      var on_scroll = function () {
        var scrolled = $window.document.body.scrollTop;
        switch (attrs.action) {
        case 'show':
          if (scrolled > attrs.top) {
            e.style.visibility = 'visible';
          } else {
            e.style.visibility = 'hidden';
          }
          break;
        case 'move':
          e.style.top = orig_top;
          if (scrolled > attrs.top) {
            e.style.top = attrs.offset + 'px';
            e.style.position = 'fixed';
          }
          break;
        }
      };

      scope.$on('resize', on_scroll);
      scope.$on('scroll', on_scroll);
    },
  };
});
