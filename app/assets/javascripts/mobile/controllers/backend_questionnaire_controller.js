/*globals angular, unused */
angular.module('workships-mobile').controller('backendQuestionnaireController', ['$scope', function ($scope) {
  'use strict';

  $scope.init = function (questionnaire) {
    var i;
    $scope.company_in_edit_state = [];
    $scope.company_in_delete_state = [];
    for (i = 0; i < questionnaire; i++) {
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
