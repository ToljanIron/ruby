/*globals angular */
angular.module('workships.directives').directive('toggle', function ($timeout) {
  'use strict';
  return {
    scope: {
      state: '=',
      callback: '&'
    },
    template: "<div class='toggle-wrapper'>" +
                "<div class='white-blocker left'></div>" +
                "<div class='toggle-box' ng-click='flipToggle()' ng-class='{on: isStateOn()}'>" +
                  "<div class='toggle-text on' ng-class='{show: isStateOn()}'>on</div>" +
                  "<div class='toggle-text off' ng-class='{show: !isStateOn()}'>off</div>" +
                  "<div class='toggle-flipper' ng-class='{on: isStateOn()}'></div>" +
                "</div>" +
                "<div class='white-blocker right'></div>" +
              "</div>",
    link: function (scope) {
      scope.flipToggle = function () {
        scope.state = !scope.state;
        if (scope.callback) {
          $timeout(scope.callback);
        }
      };
      scope.isStateOn = function () {
        return scope.state;
      };
    }
  };
});