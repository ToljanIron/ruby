/*global angular, $compile, unused */
angular.module('workships-mobile.directives').directive('pillbox', function () {
  'use strict';
  return {
    restrict: 'E',
    template:
      "<div class='pillbox'> " +
      "<img class='remove-btn clickable' ng-click='onClickRemove()' ng-src='assets/questionnaire_imgs/delete_x.png'>" +
      "<div class='name' title='{{name}}'> {{name}} </div>" +
      "</div>",
    scope: {
      name: '=',
      onRemove: '&',
    },
    link: function (scope) {
      unused(scope);
      scope.onClickRemove = function () {
        scope.onRemove();
      };
    }
  };
});