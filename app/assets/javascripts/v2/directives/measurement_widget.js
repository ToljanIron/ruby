/*global angular, JST, $compile, unused */
angular.module('workships.directives').directive('measurementWidget', function () {
  'use strict';
  return {
    template: "<div class='measurement-widget-container'> " +
              "<div class='headline'> " +
              "</div>" +
              "</div>",
    scope: {
      positive: '=',
      numOfSquares: '=',
      departmentName: '=',
      metricName: '='
    },
    link: function (scope) {
      console.log('scope', scope);
    }
  };
});