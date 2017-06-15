/*global angular, JST, $compile, unused */
angular.module('workships.directives').directive('metricWidgetDirective', function () {
  'use strict';
  return {
    restrict: 'E',
    template: JST['v2/metric_widget'](),
    scope: {
      measureData: '=',
      externalDataMetric: '=',
      metricId: '=',
    },
  };
});