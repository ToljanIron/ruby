/*global angular, JST, $compile, unused */
/* istanbul ignore next */
angular.module('workships.directives').directive('flagWidget', function () {
  'use strict';
  return {
    restrict: 'E',
    template: JST['v2/flag_widget'](),
    scope: {
      flagData: '=',
      indexPos: '=',
      flagName: '=',
      color: '=',
    },
  };
});
