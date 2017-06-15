/*global angular, JST, unused,setTimeout, document, window*/

angular.module('workships.directives').directive('fullscreen', function (fullScreenEventService,overlayBlockerService) {
  'use strict';
  return {
    restrict: 'AE',
    link: function (scope) {
      var event_happen = false;
      function exitHandler() {
        if (document.webkitIsFullScreen || document.mozFullScreen || document.msFullscreenElement !== null) {
          event_happen = !event_happen;
          fullScreenEventService.setEvent(event_happen);
          overlayBlockerService.unblock();
          scope.$apply();
        }
      }
      if (document.addEventListener) {
        document.addEventListener('webkitfullscreenchange', exitHandler, false);
        document.addEventListener('mozfullscreenchange', exitHandler, false);
        document.addEventListener('fullscreenchange', exitHandler, false);
        document.addEventListener('MSFullscreenChange', exitHandler, false);
      }
      scope.$on('$destroy', function () {
        document.removeEventListener('webkitfullscreenchange', exitHandler);
        document.removeEventListener('mozfullscreenchange', exitHandler);
        document.removeEventListener('fullscreenchange', exitHandler);
        document.removeEventListener('MSFullscreenChange', exitHandler);
      });
    }
  };
});
