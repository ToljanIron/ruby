/*globals angular */

angular.module('workships.directives').directive('checkbox', function () {

  'use strict';

  return {

    replace: true,

    scope: {
      onCallback: '&',
      offCallback: '&',
      value: '=',
      text: '@',
      uncheckdisabled: '@',
      src: '@',
      disabled: '@',
      checkTextDirection: '@'
    },

    template: '<div class="checkbox_directive">' +
                '<div ng-click="onClick()" class="checkbox" ng-class="{disabled: toBoolean(disabled)}">' +
                  '<span ng-show="value"><img ng-src={{src}}></span>' +
                '</div>' +
                '<span style=\'direction: {{direction}};\' class="checkbox_text" ng-class="{disabled: toBoolean(disabled)}">{{text}}</span>' +
              '</div>',

    controller: function ($scope) {

      var isHebrew = function(text) {
        if (text === undefined) { return false; }
        return (text.match(/[\u05D0-\u05FF]+/) !== null);
      };

      var setTextDirection = function(text, checkTextDirection) {
        if (checkTextDirection) { return 'ltr'; }
        if (isHebrew(text)) { return 'rtl'; }
        return 'ltr';
      };

      $scope.direction = setTextDirection($scope.text, $scope.checkTextDirection);

      $scope.toBoolean = function (str) {
        if (str === 'true' || str === true) {
          return true;
        }
        if (str === 'false' || str === false) {
          return false;
        }
        return false;
      };

      $scope.onClick = function () {
        if ($scope.value === true && $scope.toBoolean($scope.uncheckdisabled) || $scope.toBoolean($scope.disabled)) {
          return;
        }
        if ($scope.onCallback && !$scope.value) {
          $scope.onCallback();
        } else if ($scope.offCallback && $scope.value) {
          $scope.offCallback();
        }
      };
    }
  };
});

