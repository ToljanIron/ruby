/*globals angular, unused */
angular.module('workships-mobile').controller('companiesController', ['$scope', function ($scope) {
  'use strict';

  $scope.init = function (companies_count) {
    var i;
    $scope.company_in_edit_state = [];
    $scope.company_in_delete_state = [];
    for (i = 0; i < companies_count; i++) {
      $scope.company_in_edit_state[i] = false;
      $scope.company_in_delete_state[i] = false;
    }
  };

  $scope.toggleEditState = function (i) {
    $scope.company_in_edit_state[i] = !$scope.company_in_edit_state[i];
  };

  $scope.toggleDeleteState = function (i) {
    $scope.company_in_delete_state[i] = !$scope.company_in_delete_state[i];
  };

}]);
