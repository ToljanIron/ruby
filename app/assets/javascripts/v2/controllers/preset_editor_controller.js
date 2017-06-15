/*globals angular, _, unused */
angular.module('workships').controller('presetEditorController', function ($scope, editPresetMediator, dataModelService) {
  'use strict';
  /* istanbul ignore next */
  $scope.getGroupName = function (gid) {
    return dataModelService.getGroupBy(gid).name;
  };
  /* istanbul ignore next */
  $scope.getEmployeeName = function (emp_email) {
    var emp = dataModelService.getEmployeeByEmail(emp_email);
    if (emp) {
      return emp.first_name + " " + emp.last_name;
    }
  };
  $scope.getFilterName = function (cond) {
    var cretria;
    if (cond.param === 'rank_2') {
      cretria = 'Rank' + " ";
    } else if (cond.param === 'age_group') {
      cretria = 'Age' + " ";
    } else {
      cretria = cond.param + " ";
    }
    _.each(cond.vals, function (val, index) {
      if (index === 0) {
        cretria += '(';
      }
      cretria +=  val + ',';
      if (index === cond.vals.length - 1) {
        cretria = cretria.slice(0, -1);
        cretria += ')';
      }
    });
    return cretria;
  };

  $scope.init = function () {
    $scope.preset = editPresetMediator;
    $scope.available_opers = ['in', 'not in'];
    $scope.select = {};
    $scope.available_filters = {};
    $scope.employees = [];
  };
});