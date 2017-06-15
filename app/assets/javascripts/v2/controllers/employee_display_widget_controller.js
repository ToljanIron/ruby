/*globals angular, _ , window, unused*/

angular.module('workships').controller('employeeDisplayWidgetController', function ($scope, directoryMediator, sidebarMediator, dashboradMediator, employeeWidgetFactoryService) {
  'use strict';
  $scope.GROUP_VIEW = 'true';
  var addTheResultToScope = function (new_display_list) {
    $scope.first_index_in_display_list = new_display_list.first;
    $scope.last_index_in_display_list = new_display_list.last;
    $scope.displayed_range = [$scope.first_index_in_display_list, $scope.last_index_in_display_list];
  };

  var initDisplayList = function (employee_list) {
    employee_list = _.sortBy(employee_list, function (o) { return -o.current_avg; });
    var index = 0;
    _.each(employee_list, function (o) {
      o.index = index;
      index += 1;
    });
    var res = employeeWidgetFactoryService.initDisplayList(employee_list);
    addTheResultToScope(res);
    $scope.employee_list = employee_list;
  };

  $scope.addToBeginEmployeeList = function () {
    var new_display_list = employeeWidgetFactoryService.getToBeginEmployeesList($scope.employee_list);
    addTheResultToScope(new_display_list);
  };

  $scope.nextEmployee = function () {
    var new_display_list = employeeWidgetFactoryService.getTheNextEmployee($scope.employee_list,
      $scope.first_index_in_display_list, $scope.last_index_in_display_list, $scope.employeeDisplayNumber.number);
    addTheResultToScope(new_display_list);
  };
  $scope.addToEndEmployeeList = function () {
    var new_display_list = employeeWidgetFactoryService.getTheEndEmployeesList($scope.employee_list,
      $scope.employeeDisplayNumber.number);
    addTheResultToScope(new_display_list);
  };

  $scope.beforeEmplyee = function () {
    var new_display_list = employeeWidgetFactoryService.getThePreviousEmployees($scope.employee_list,
      $scope.first_index_in_display_list, $scope.last_index_in_display_list, $scope.employeeDisplayNumber.number);
    addTheResultToScope(new_display_list);
  };

  $scope.displayTwoDigitsAfterDecimal = employeeWidgetFactoryService.displayTwoDigitsAfterDecimal;

  $scope.$watch('employeeListDetails', function () {
    if ($scope.employeeListDetails) {
      initDisplayList($scope.employeeListDetails);
    }
  });
  $scope.goToPersonalCard = function (emp) {
    if ($scope.selected.group_overoll_state === $scope.GROUP_VIEW) {
      $scope.directoryMediator.setEmplyeeId(emp.id);
      $scope.sidebar.change_to_employee_page = true;
      window.location.href = '/#/directory';
    }
  };
  $scope.init = function () {
    $scope.selected = dashboradMediator;
    $scope.directoryMediator = directoryMediator;
    $scope.sidebar = sidebarMediator;
    $scope.displayed_range = [0, 10];
    unused();
  };

});
