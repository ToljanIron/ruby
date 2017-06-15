/*globals angular , $ ,  window , KeyLines ,document ,console, unused */
angular.module('workships').controller('ResetPasswordController', function ($scope, ajaxService, passwordsService, tokenService) {
  'use strict';
  var self = this;
  $scope.init = function () {
    $scope.tokenService = tokenService;
    $scope.user = {};
    $scope.error = {};
    $scope.error.email = true;
    $scope.change_user = false;
    $scope.password_match = true;
    $scope.change_password = false;
    $scope.passwords_verified = true;
    $scope.passwordsService = passwordsService;
    var urlArr = window.location.href.split(/\?|\=/);
    self.set_password_token = urlArr[2];
  };

  self.onSuccessUpdatePassword = function () {
    window.location.href = '/signin';
  };

  $scope.onClickResetPassword = function () {
    if ($scope.user.password !== $scope.user.password_confirmation) {
      $scope.password_match = false;
      $scope.passwords_verified = true;
      return;
    }
    if ($scope.passwordsService.verifyPasswords($scope.user.password, $scope.user.password_confirmation)) {
      ajaxService.getPromise('POST', '/update_reset_new_password', { user_id: self.user_id, password: $scope.user.password, password_confirmation: $scope.user.password_confirmation, token: self.set_password_token }).then(
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