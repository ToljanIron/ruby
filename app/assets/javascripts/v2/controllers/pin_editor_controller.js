/*globals angular, _, unused */
angular.module('workships').controller('PinEditorController', function ($scope, ajaxService, dataModelService) {
  'use strict';

  function getDefinitionList() {
    var params = {
      company_id: 1
    };
    var onSucc = function (data) {
      $scope.available_filters = data;
      $scope.available_params = _.keys($scope.available_filters);
      $scope.select = {};
    };
    var onErr = function (error) {
    };
    ajaxService.sendMsg('GET', '/API/get_filters', params, onSucc, onErr);
  }

  $scope.onClickSave = function (pin) {
    var onSucc = function () {
    };
    var onErr = function (error) {
    };
    ajaxService.sendMsg('POST', '/API/newpin', pin, onSucc, onErr);
  };

  $scope.onClickDelete = function (pin) {
    var onSucc = function () {
      $scope.pins = _.without($scope.pins, pin);
    };
    var onErr = function (error) {
    };
    ajaxService.sendMsg('POST', '/API/delete_pins', pin, onSucc, onErr);
  };

  $scope.onClickPinTitle = function (pin) {
    $scope.selected = pin;
  };

  $scope.availableValsForParam = function (param) {
    return $scope.available_filters[param];
  };

  $scope.onClickParamVal = function (cond, val) {
    if (_.contains(cond.vals, val.value)) {
      cond.vals = _.without(cond.vals, val.value);
    } else {
      cond.vals.push(val.value);
    }
  };

  $scope.doesCondHaveValue = function (cond, val) {
    return _.contains(cond.vals, val.value);
  };

  $scope.onClickAddFilter = function (pin) {
    /*   if (pin === undefined || pin === null) {
         $scope.onClickNewPin();
         $scope.selected = pin;
       }*/
    pin.definition.conditions.push({
      param: $scope.available_params[0],
      vals: [],
      oper: $scope.available_opers[0],
    });
  };

  $scope.onClickNewPin = function () {
    $scope.pins.push({
      company_id: 1,
      name: '**NEW**',
      definition: {
        conditions: [],
        employees: []
      }
    });

    $scope.select = _.last($scope.pins);
  };

  $scope.onClickDelFilter = function (pin, cond) {
    pin.definition.conditions = _.without(pin.definition.conditions, cond);
  };

  $scope.doesPinContainEmployee = function (pin, employee) {
    if ($scope.select !== -1) {
      return _.contains(pin.definition.employees, employee.email);
    }
  };

  $scope.onClickPinEmployee = function (pin, employee) {
    if (_.contains(pin.definition.employees, employee)) {
      pin.definition.employees = _.without(pin.definition.employees, employee.email);
    } else {
      if (pin.definition.employees === null || pin.definition.employees === undefined) {
        pin.definition.employees = [];
      }
      pin.definition.employees.push(employee.email);
    }
  };

  $scope.init = function () {
    $scope.pins = [];
    $scope.available_opers = ['in', 'not in'];
    $scope.select = {};
    $scope.available_filters = {};
    $scope.employees = [];

    getDefinitionList();
    dataModelService.getEmployees().then(function (employees_list) {
      $scope.employees = employees_list;
    });
    dataModelService.getPins().then(function (data) {
      $scope.pins = data;
    });
  };
});
