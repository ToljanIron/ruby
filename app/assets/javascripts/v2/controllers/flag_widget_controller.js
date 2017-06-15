/*globals angular , unused, window, document, $, _*/

angular.module('workships').controller('flagsWidgetController', function ($scope, dataModelService, analyzeMediator, tabService, StateService, dashboradMediator, utilService) {
  'use strict';
  var self = this;
  $scope.BOTTOM_UP_VIEW = true;
  $scope.EMP = 'emp';
  var FLAG = 2;
  $scope.GROUP = 'group';
  var PATH = 'assets/analyze_color/';
  var IMAGE_PATH = 'assets/flag_imgs/';
  var EXTENSION = '.png';
  var STRUCTURE = 'formal_structure';
  var changeDisplayedRange = function (delta) {
    var widget_size = $scope.employee_display_number.number;
    var data_size = $scope.flag_data.ret_list.length;
    var new_min = $scope.displayed_range[0] + delta;
    var new_max = new_min + widget_size;
    if (new_min < 0) {
      return;
    }
    if (new_max > data_size) {
      new_max = data_size;
      new_min = new_max - widget_size;
    }
    $scope.displayed_range = [new_min, new_max];
  };

  $scope.prev = function () {
    changeDisplayedRange(-1);
  };
  $scope.set_color =  function (last, g_id) {
    if (last) {
      var color = $scope.dm.getColorsByName(STRUCTURE, g_id) || '8dc0c5';
      return { color: '#' + color };
    }
  };

  $scope.next = function () {
    changeDisplayedRange(1);
  };
  var AddEmployeesToGroup = function (group) {
    var res = [];
    var emp_list = $scope.dm.getGroupBy(group.id).employees_ids;
    _.each($scope.flag_data.ret_list, function (employee) {
      if (_.include(emp_list, employee.id)) {
        res.push(employee);
      }
    });
    return res;
  };

  self.getIndexOfCurrentGroupSelected = function (bread_crumbs) {
    var current_index;
    _.each(bread_crumbs, function (group_level, index) {
      if (group_level.id === $scope.selected.id) {
        current_index = index;
      }
    });
    return current_index;
  };
  self.createEmployeeAndGroupListToWidget = function (g_id) {
    $scope.emps_with_details = [];
    var color;
    var children = $scope.dm.getGroupDirectChilds(g_id);
    if ($scope.flag_data) {
      $scope.index = 0;
      _.each(children, function (child) {
        var tmp_child_group = {};
        tmp_child_group.type = $scope.GROUP;
        tmp_child_group.group_parent = g_id;
        tmp_child_group.display_name = child.name;
        tmp_child_group.id = child.id;
        color = $scope.dm.getColorsByName(STRUCTURE, tmp_child_group.id) || '8dc0c5';
        tmp_child_group.img_url =  PATH + color + EXTENSION;
        tmp_child_group.employee_number = AddEmployeesToGroup(child);
        tmp_child_group.employee_number = tmp_child_group.employee_number.length;
        if (tmp_child_group.employee_number !== 0) {
          tmp_child_group.index = $scope.index;
          $scope.index++;
          $scope.emps_with_details.push(tmp_child_group);
        }
      });
      _.each($scope.flag_data.ret_list, function (employee) {
        var tmp_child_group = {};
        var emp_details = $scope.dm.getEmployeeById(employee.id);
        if (emp_details.group_id === g_id) {
          tmp_child_group.index = $scope.index;
          $scope.index++;
          tmp_child_group.type = $scope.EMP;
          tmp_child_group.img_url = emp_details.img_url;
          tmp_child_group.group_parent = g_id;
          var emp_name = emp_details.first_name + " " + emp_details.last_name;
          tmp_child_group.display_name = utilService.employeeDisplayName(emp_name, emp_details.email);
          tmp_child_group.id = emp_details.id;
          tmp_child_group.group_id = emp_details.group_id;
          $scope.emps_with_details.push(tmp_child_group);
        }
      });
    }
  };

  var createEmployeeListToWidget = function () {
    $scope.emps_with_details = [];
    if ($scope.flag_data) {
      _.each($scope.flag_data.ret_list, function (employee, index) {
        var emp_from_list;
        var tmp_employee = {};
        tmp_employee.index = index;
        emp_from_list = dataModelService.getEmployeeById(employee.id);
        tmp_employee.id = emp_from_list.id;
        tmp_employee.img_url = emp_from_list.img_url;
        var emp_name = emp_from_list.first_name + " " + emp_from_list.last_name;
        tmp_employee.display_name = utilService.employeeDisplayName(emp_name, emp_from_list.email);

        $scope.emps_with_details.push(tmp_employee);
      });
    }
  };

  var employeesSuccess = function (employee_list) {
    $scope.employee_list = employee_list;
    if ($scope.selected.group_overoll_state === $scope.BOTTOM_UP_VIEW) {
      createEmployeeListToWidget();
      $scope.displayed_range = [0, employee_list.length - 1];
    } else {
      self.createEmployeeAndGroupListToWidget($scope.selected.id);
      $scope.displayed_range = [0, employee_list.length - 1];
    }
  };

  $scope.removeSubGroup = function (g_id) {
    if (g_id !== $scope.selected.id) {
      var parent_id = $scope.dm.getGroupBy(g_id).parent;
      if (parent_id === $scope.selected.id) {
        $scope.show_bredcrumbs = false;
      } else {
        $scope.bread_crumbs_list = $scope.dm.getBreadCrumbs(parent_id, $scope.selected.type);
      }
      self.createEmployeeAndGroupListToWidget(parent_id);
    } else {
      $scope.show_bredcrumbs = false;
    }
  };

  $scope.selectGroup = function (g_id) {
    $scope.addSubGroupFlag(g_id, $scope.GROUP);
  };

  $scope.addSubGroupFlag = function (g_id, type) {
    if (type === $scope.GROUP) {
      $scope.bread_crumbs_list = $scope.dm.getBreadCrumbs(g_id, $scope.selected.type);
      $scope.current_group_index = self.getIndexOfCurrentGroupSelected($scope.bread_crumbs_list);
      $scope.show_bredcrumbs = true;
      self.createEmployeeAndGroupListToWidget(g_id);
    }
  };

  $scope.isEmptyFlag = function () {
    if (!$scope.emps_with_details) { return true; }
    return $scope.emps_with_details.length === 0;
  };

  var on_resize = function () {
    var employee_display = {};
    var result = document.getElementsByClassName("flag-widget-container");
    var e = result[$scope.indexPos];
    if (!e) {
      return;
    }
    var width;
    var mocking = true;
    var orig_bounding_rect = $(e.parentNode.parentNode.parentNode);
    var orig_width = orig_bounding_rect.width();
    switch (mocking) {
    case orig_width >= 0 && orig_width <= 600:
      width = 353;
      employee_display.number = 2;
      break;
    case orig_width >= 600 && orig_width <= 840:
      width = 587;
      employee_display.number = 4;
      break;
    case orig_width > 840 && orig_width <= 1295:
      width = 938;
      // 821
      employee_display.number = 7;
      break;
    case orig_width > 1295 && orig_width <= 1390:
      width = 1028;
      employee_display.number = 8;
      break;
    case orig_width > 1390:
      width = 1170;
      employee_display.number = 9;
      break;
    }
    e.style.width = width + 'px';
    $scope.flaggedEmpBoxWidth = "{'width': " + width + "'px'}";
    $scope.employee_display_number = employee_display;
  };
  var resize_promise = $scope.$on('resize', on_resize);

  $scope.$on('restart', function () {
    $scope.$on('resize', on_resize);
  });

  $scope.$on('stop', function () {
    resize_promise();
  });

  $scope.$watch('[flagData, selected.group_overoll_state]', function () {
    if ($scope.flagData) {
      $scope.flag_data = $scope.flagData;
      if ($scope.selected.group_overoll_state === $scope.BOTTOM_UP_VIEW) {
        createEmployeeListToWidget();
      } else {
        $scope.show_bredcrumbs = false;
        self.createEmployeeAndGroupListToWidget($scope.selected.id);
      }
      if($scope.employee_list !== undefined) {
        $scope.displayed_range = [0, $scope.employee_list.length - 1];
      }
    }
  }, true);

  $scope.numOfEmployeesLargerThanSize = function () {
    return;
  };

  $scope.getColor = function () {
    return { 'color': $scope.color };
  };
  $scope.jumpToExplore = function () {
    var emps_flag = [];
    console.log("FWC - resetChartState");
    analyzeMediator.resetChartState();
    analyzeMediator.setFlagData(emps_flag, $scope.flagName, tabService.current_tab, $scope.flag_data.analyze_company_metric_id, FLAG, $scope.flag_data.company_metric_id);
    analyzeMediator.setSelected(StateService.get(tabService.current_tab + '_selected'), 'group');
    tabService.selectTab('Explore');
  };

  $scope.jumpToExploreImage = function () {
    if (tabService.current_tab === 'Explore' || tabService.current_tab === 'Dashboard') { return; }
    return IMAGE_PATH + 'jump_to_' + tabService.current_tab + EXTENSION;
  };

  $scope.init = function () {
    $scope.show_bredcrumbs = false;
    $scope.flag_data = $scope.flagData;
    $scope.selected = dashboradMediator;
    $scope.dm = dataModelService;
    $scope.flagged_emps = [];
    dataModelService.getEmployees().then(employeesSuccess);
    on_resize.call();
  };
});
