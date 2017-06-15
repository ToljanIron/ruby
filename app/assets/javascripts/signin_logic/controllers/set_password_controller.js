/*globals angular , $ ,  window ,_ , unused */
angular.module('workships').controller('setPasswordController', function ($scope, passwordsService, ajaxService) {
  'use strict';

  var self = this;

  // *******  Init  *******
  $scope.init = function () {
    $scope.user = {};
    $scope.error = {};
    $scope.password_match = true;
    $scope.error.email = true;
    $scope.change_user = false;
    $scope.change_password = false;
    $scope.passwords_verified = true;
    $scope.passwordsService = passwordsService;

  };

  self.onSuccessUpdatePassword = function () {
    window.location.href = '/signin';
  };

  self.onFailUpdatePassword = function () {
    $scope.passwords_verified = false;
  };

  $scope.onClickSetPassword = function () {
    if ($scope.user.password !== $scope.user.password_confirmation) {
      $scope.password_match = false;
      $scope.passwords_verified = true;
      return;
    }
    if ($scope.passwordsService.verifyPasswords($scope.user.password, $scope.user.password_confirmation)) {
      ajaxService.getPromise('POST', '/update_set_new_password', { user_id: self.user_id, password: $scope.user.password, password_confirmation: $scope.user.password_confirmation, token: $scope.set_password_token }).then(
        self.onSuccessUpdatePassword,
        self.onFailUpdatePassword
      );
      $scope.passwords_verified = true;
      $scope.password_match = true;
    } else {
      $scope.passwords_verified = false;
      $scope.password_match = true;
    }
  };


});
