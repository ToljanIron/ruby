/*global angular, JST, $compile, unused */
angular.module('workships.directives').directive('graphWidgetDirective', function () {
  'use strict';
  return {
    restrict: 'E',
    transclude: true,
    template: JST['v2/graph_widget'](),
    scope: {
      measureData: '=',
      selected: '=',
      graphsize: '=',
      externalDataMetric: '=',
      metricId: '=',
    },
  };
});
