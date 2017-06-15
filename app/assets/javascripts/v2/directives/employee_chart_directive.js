/*global angular, JST, $compile, unused */
/* istanbul ignore next */
angular.module('workships.directives').directive('employeeChartDirective', function () {
  'use strict';
  return {
    restrict: 'E',
    template: JST['v2/employee_chart'](),
    scope: {
      currentMonthGlobalTrend: '@',
      lastMonthGlobalTrend: '@',
      lastMonthEmployeeTrend: '@',
      currentMonthEmployeeTrend: '@',
    },
  };
});
