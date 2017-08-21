/*globals angular, document */

angular.module('workships-mobile.directives').directive('preventZoom', ['$timeout', function ($timeout) {
  'use strict';

  return {
    link: function (scope, element) {
      angular.noop(scope);
      $timeout(function () {
        element.on('touchstart', function (e) {
          var t2 = e.timeStamp,
          t1 = element.data('lastTouch') || t2,
          dt = t2 - t1,
          fingers = e.touches.length;
          element.data('lastTouch', t2);
          if (!dt || dt > 700 || fingers > 1) { return; } // not double-tap
          e.preventDefault();
          element.triggerHandler('click');
        });
      });
    }
  };

}]);
