/*globals angular , window, unused, _, alert */
angular.module('workships').controller('adminController', function ($scope, $http) {
  'use strict';

  $scope.changeTab = function (tab) {
    $scope.curr_tab = tab;
  };
  var initTabs = function () {
    $scope.COMPANY_TAB = 1;
    $scope.PERMISSIONS_TAB = 2;
    $scope.CREATE_COMPANY_TAB = 3;
    $scope.curr_tab = $scope.COMPANY_TAB;
  };
  function initEditModes(e) {
    var i;
    $scope.employee_in_edit_state = [];
    $scope.employee_in_delete_state = [];
    for (i = 0; i < e; i++) {
      $scope.employee_in_edit_state[i] = false;
      $scope.employee_in_delete_state[i] = false;
    }
  }
  function initCreateCompany() {
    $scope.new_company = {
      name: '',
      domains: [
        {
          name: '',
          service: ''
        }
      ]
    };
  }

  $scope.init = function (companies_count) {
    initTabs();
    initEditModes(companies_count);
    initCreateCompany();
  };

  $scope.toggleEmployeeDeleteState = function (i) {
    $scope.employee_in_delete_state[i] = !$scope.employee_in_delete_state[i];
  };
  $scope.toggleEmployeeEditState = function (i) {
    $scope.employee_in_edit_state[i] = !$scope.employee_in_edit_state[i];
  };

  $scope.addCompanyDomain = function () {
    $scope.new_company.domains.push({name: '', service_id: 1});
  };

  $scope.showRemoveButton = function (domain) {
    return _.indexOf($scope.new_company.domains, domain) > 0;
  };

  $scope.removeCompanyDomain = function (domain) {
    _.remove($scope.new_company.domains, function (d) {
      return d === domain;
    });
  };

  function companyNameValid() {
    return $scope.new_company.name.length > 0;
  }

  function domainNameValid(domain) {
    return domain.name.length > 0;
  }

  function companyValid() {
    return _.all($scope.new_company.domains, function (domain) {
      return domainNameValid(domain);
    }) && companyNameValid();
  }

  $scope.createCompany = function () {
    if (companyValid()) {
      $http.post('company/create', { data: $scope.new_company }).success(function (msg) {
        if (msg.error) {
          alert(msg.error);
        } else {
          $scope.changeTab($scope.COMPANY_TAB);
        }
      }).error(function () {
        alert('Error! Please try again.');
      });
    } else {
    }
  };

});
