/*global angular, $compile, unused */
angular.module('workships.directives').directive('questionnaireStatisticInfo', function () {
  'use strict';
  return {
    restrict: 'E',
    template:
      "<div class='statistic-info'> " +
      "<div class='info-name'> {{headingName}} </div>" +
      "<div class='info-percentage' ng-style='{color: valueColor}'> {{value || '-'}} </div>" +
      "<div ng-show='seprate === true' class='sperate' ng-style=\"{'background-color': seperateColor}\"></div>" +
      "</div>",
    scope: {
      headingName: '=',
      value: '=',
      seprate: '=',
      seperateColor: '=',
      valueColor: '='
    },
    link: function (scope) {
      unused(scope);
    }
  };
});
