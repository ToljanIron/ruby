/*global angular, JST, $compile, unused */
/* istanbul ignore next */
angular.module('workships.directives').directive('employeeDisplayWidgetDirective', function () {
  'use strict';
  return {
    restrict: 'E',
    template: JST['v2/employee_display_widget'](),
    scope: {
      employeeDisplayNumber: '=',
      employeeListDetails: '=',
      selected: '=',
    },
  };
});
