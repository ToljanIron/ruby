/*globals angular , unused, _, $*/

angular.module('workships').controller('metricWidgetController', function ($scope, $element, dashboradMediator, dataModelService, utilService) {
  'use strict';

  // $scope.GROUP_STATE = 'group';
  $scope.BOTTOM_UP_VIEW = true;
  // $scope.OVERALL_STATE = 'overall';
  var PATH = 'assets/analyze_color/';
  var EXTENSION = '.png';
  var STRUCTURE = 'formal_structure';
  var getEmployeeDetailsFromEmployeeList = function (employee) {
    return _.find($scope.employee_list, function (emp) {
      return parseInt(emp.id, 10) === employee.id;
    });
  };

  var getLastAverageForEmployee = function (employee, before_employee_list) {
    var last_avg;
    if (_.isEmpty(before_employee_list) || before_employee_list === undefined || before_employee_list === null) {
      last_avg = 0;
    } else {
      var tmp_employee = _.find(before_employee_list, function (emp) {
        return emp.id === employee.id;
      });
      if (tmp_employee === undefined || tmp_employee === null) {
        last_avg = 0;
      } else {
        last_avg = tmp_employee.measure;
      }
    }
    return last_avg;
  };
  var calculateAverage = function (child_group_emp_list) {
    if (!child_group_emp_list || child_group_emp_list.length === 0) {
      return 0;
    }
    var sum = 0;
    _.each(child_group_emp_list, function (emp) {
      sum += emp.measure;
    });
    return (sum / child_group_emp_list.length);
  };

  var addGroupsToList = function (group_to_view, before_group_list) {
    $scope.employee_list_details = [];
    var index = 0;
    _.each(group_to_view, function (c_group, g_id) {
      var temp_group = {};
      temp_group.current_avg = calculateAverage(c_group);
      temp_group.last_avg = calculateAverage(before_group_list[g_id]);
      temp_group.display_name = dataModelService.getGroupBy(g_id).name;
      var color = dataModelService.getColorsByName(STRUCTURE, g_id) || '8dc0c5';
      temp_group.img_url =  PATH + color + EXTENSION;
      temp_group.index = index;
      index++;
      $scope.employee_list_details.push(temp_group);
    });
  };

  var getDirectGroupsWithAllEmployeesUnderThem = function (children, child_groups) {
    var res = {};
    _.each(children, function (child) {
      var child_id = child;
      res[child_id] = child_groups[child_id];
      var sub_group = dataModelService.getGroupBy(child).child_groups;
      _.each(sub_group, function (g_id) {
        res[child_id] =  _.union(res[child_id], child_groups[g_id]);
      });
    });
    return res;
  };
  var getAllSubGroupsWithDirectEmployeeId = function (current_employee_list) {
    var res = {};
    _.each(current_employee_list, function (emp) {
      var emp_group_id = dataModelService.getEmployeeById(emp.id).group_id;
      if (emp_group_id) {
        if (!res[emp_group_id]) {
          res[emp_group_id] = [];
        }
        res[emp_group_id].push(emp);
      }
    });
    return res;
  };

  var createEmployeeListToWidget = function (current_employee_list, before_employee_list) {
    $scope.employee_list_details = [];
    _.each(current_employee_list, function (employee, index) {
      var emp_from_list;
      var tmp_employee = {};
      tmp_employee.pay_attention_flag = employee.pay_attention_flag;
      tmp_employee.index = index;
      tmp_employee.current_avg = employee.measure;
      tmp_employee.last_avg = getLastAverageForEmployee(employee, before_employee_list);
      emp_from_list = getEmployeeDetailsFromEmployeeList(employee);
      tmp_employee.id = emp_from_list.id;
      tmp_employee.img_url = emp_from_list.img_url;
      var emp_name = emp_from_list.first_name + ' ' + emp_from_list.last_name;
      tmp_employee.display_name = utilService.employeeDisplayName(emp_name, emp_from_list.email);
      $scope.employee_list_details.push(tmp_employee);
    });
  };
  var getDirectSubGroubWithAllEmployees = function (employee_list, children) {
    var child_groups = getAllSubGroupsWithDirectEmployeeId(employee_list);
    return getDirectGroupsWithAllEmployeesUnderThem(children, child_groups);
  };

  var createGroupListToWidget = function (current_employee_list, before_employee_list) {
    var children;
    if (current_employee_list[0].id) {
      children = dataModelService.getGroupDirectChildsList($scope.dashborad_mediator.id);
      var group_to_view = getDirectSubGroubWithAllEmployees(current_employee_list, children);
      var before_group_list = getDirectSubGroubWithAllEmployees(before_employee_list, children);
      addGroupsToList(group_to_view, before_group_list);
      return;
    }
    $scope.employee_list_details = [];
    var index = 0;
    _.each(current_employee_list, function (group) {
      var g_id = group.group_id;
      var score = group.score;
      var temp_group = {};
      temp_group.current_avg = score;
      if (before_employee_list && before_employee_list.length > 0) {
        var last_avg_score = _.find(before_employee_list, {'group_id': g_id });
        temp_group.last_avg = last_avg_score.score;
      } else {
        var current_avg_score = _.find(current_employee_list, {'group_id': g_id });
        temp_group.last_avg = current_avg_score.score;
      }
      temp_group.display_name = dataModelService.getGroupBy(g_id).name;
      var color = dataModelService.getColorsByName(STRUCTURE, g_id) || '8dc0c5';
      temp_group.img_url =  PATH + color + EXTENSION;
      temp_group.index = index;
      index++;
      $scope.employee_list_details.push(temp_group);
    });
  };

  var createEmployeeListFromSnapshot = function (snapshots_list, snapshot_id, prev_snapshot_id) {
    var current_employee_list = snapshots_list[snapshot_id];
    var before_employee_list = snapshots_list[prev_snapshot_id];
    if ($scope.dashborad_mediator.group_overoll_state === $scope.BOTTOM_UP_VIEW) {
      createEmployeeListToWidget(current_employee_list, before_employee_list);
    } else {
      createGroupListToWidget(current_employee_list, before_employee_list);
    }
  };

  var employeesSuccess = function (employee_list) {
    $scope.employee_list = employee_list;
  };

  var on_resize = function () {
    var employee_display = {};
    var graph_size = {};
    var e = $element[0];

    var width;
    var mocking = true;
    var orig_width = $(e.parentNode.parentNode.parentNode).width();
    switch (mocking) {
    case orig_width >= 0 && orig_width < 650:
      width = 353;
      employee_display.number = 3;
      graph_size.number = 3;
      break;
    case orig_width >= 650 && orig_width <= 840:
      width = 587;
      employee_display.number = 5;
      graph_size.number = 5;
      break;
    case orig_width > 840 && orig_width <= 1100:
      width = 821;
      employee_display.number = 7;
      graph_size.number = 7;
      break;
    case orig_width > 1100 && orig_width <= 1300:
      width = 938;
      employee_display.number = 8;
      graph_size.number = 8;
      break;
    case orig_width > 1300 && orig_width <= 1400:
      width = 1055;
      employee_display.number = 9;
      graph_size.number = 9;
      break;
    case orig_width > 1400:
      width = 1172;
      employee_display.number = 10;
      graph_size.number = 10;
      break;
    }
    $scope.employeeDisplayNumber = {};
    $scope.employeeDisplayNumber.number = employee_display.number;
    $scope.graphsize = {};
    $scope.graphsize.number = graph_size.number;
    e.style.width = width + 'px';
  };
  $scope.$on('resize', on_resize);
  on_resize.call();

  // *****  watch ****** 

  $scope.$watch('[selected.change_time, dashborad_mediator.group_overoll_state]', function () {
    if ($scope.selected && $scope.selected.snapshot_id) {
      createEmployeeListFromSnapshot($scope.measureData.snapshots, $scope.selected.snapshot_id, $scope.selected.prev_snapshot_id);
    }
  }, true);

  $scope.init = function () {
    dataModelService.getEmployees().then(employeesSuccess);
    $scope.dashborad_mediator = dashboradMediator;
    $scope.selected = {};
  };
});
