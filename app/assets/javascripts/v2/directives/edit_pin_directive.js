/*global angular, JST, $compile, unused */
/* istanbul ignore next */
angular.module('workships.directives').directive('editPin', function () {
  'use strict';
  return {
    restrict: 'E',
    transclude: true,
    template: JST['v2/edit_pin'](),
    scope: {
      pin: '=',
      pinList: '=',
      page: '=',
    },
  };
});
