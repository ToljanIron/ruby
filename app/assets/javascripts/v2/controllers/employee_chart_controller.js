/*globals angular , unused*/

angular.module('workships').controller('employeeChartController', function ($scope) {
  'use strict';
  var self = this;
  var HIGHT_PER_UNIT = 3;

  self.calculateDelta = function (org_last_trend, org_current_trend, emp_last_trend, emp_current_trend) {
    var org_delta = org_current_trend - org_last_trend;
    var emp_delta = emp_current_trend - emp_last_trend;
    var delta = emp_delta - org_delta;
    return delta;
  };
  var createDeltaStyle = function (delta) {
    var height = HIGHT_PER_UNIT * Math.abs(delta);
    height = Math.min(height, 60);
    if (delta >= 0) {
      $scope.number = "+" + delta.toFixed(2);
      $scope.box = {
        'height': height + 'px'
      };
    } else {
      $scope.number = delta.toFixed(2);
      var box_height = -(HIGHT_PER_UNIT * Math.abs(delta) + 2)  + 'px';
      $scope.box = {
        'height': height,
        'transform': "rotate(180deg) translateY(" + box_height + ")",
      };
      $scope.numberStyle = {
        'transform': 'rotate(180deg)'
      };
    }
  };

  $scope.init = function () {
    var delta = self.calculateDelta($scope.lastMonthGlobalTrend, $scope.currentMonthGlobalTrend, $scope.lastMonthEmployeeTrend, $scope.currentMonthEmployeeTrend);
    createDeltaStyle(delta);
  };

});
