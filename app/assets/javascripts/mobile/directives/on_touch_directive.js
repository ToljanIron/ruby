/*globals angular, unused, localStorage, _, $, document */

angular.module('workships-mobile.directives').directive('onTouchDirective', function () {
  'use strict';
  return {
    scope: {
      onTouch: '&'
    },
    link: function (scope, elem) {
      function onTouchStart () {
        scope.onTouch();
      }
      
      var touch_start = elem[0].addEventListener("touchstart", onTouchStart);

      scope.$on('$destroy', function () {
        elem[0].removeEventListener(touch_start, "touchstart", onTouchStart);
      });  
    }
  };
});