/*global angular, JST, unused,setTimeout,  window*/

angular.module('workships.directives').directive('floaty', function ($timeout) {
  'use strict';
  return {
    restrict: 'A',
    link: function (scope, elem, attrs) {
      var e = elem[0];
      var orig_pos = window.getComputedStyle(e).getPropertyValue('position');
      var orig_bounding_rect = e.parentNode.getBoundingClientRect();
      var orig_top = orig_bounding_rect.top;

      var on_scroll = function () {
        e.style.position = orig_pos;
        e.style.top = orig_top;
        var top = e.getBoundingClientRect().top;
        if (top <= attrs.top) {
          e.style.position = 'fixed';
          e.style.top = attrs.top + 'px';
          if (attrs.topMost) {
            e.style.zIndex = '9999';
          } else if (attrs.directory) {
            e.style.zIndex = '49';
          } else {
            if (!attrs.inBlockedState) {
              e.style.zIndex = '9998';
            }
            if (attrs.dashboard) {
              e.style.top = '0px';
            }
          }
        }
        if (attrs.scrollFix === "true") {
          e.style.zIndex = '47';
          return;
        }
      };

      var on_resize = function () {
        if (attrs.fixWidth) {
          e.style.width = 0;
        }
        orig_bounding_rect = e.parentNode.getBoundingClientRect();
        var orig_left = orig_bounding_rect.left;
        var orig_right = orig_bounding_rect.right;
        var orig_width = orig_right - orig_left;
        if (attrs.fixWidth) {
          if (attrs.fixDirectory) {
            e.style.width = orig_width - 25 + 'px';
          } else {
            if (attrs.fixWidthAnalyze) {
              e.style.width = orig_width - 4 + 'px';
            } else {
              e.style.width = orig_width - 40 + 'px';
            }
          }
        }
        on_scroll.call();
      };
      scope.$on('scroll', on_scroll);
      scope.$on('resize', function () {
        on_resize.call();
      });
      on_resize.call();

      scope.$watch('force_floaty_resize.force', function (new_val) {
        if (new_val) {
          $timeout(function () {
            on_resize.call();
          }, 1000);
        }
      }, true);
    }
  };
});
