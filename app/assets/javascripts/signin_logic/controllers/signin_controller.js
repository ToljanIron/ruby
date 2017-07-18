/*globals angular , $ , document, window , KeyLines ,_ , getPromise, unused */
angular.module('workships').controller('signInController', function ($scope, $http) {
  'use strict';

  var self = this;
    //*******  Watch *******
  $scope.$watch('user.name', function (o, n) {
    if (!_.isEqual(o, n)) {
      $scope.change_user = false;
      $scope.empty = true;
    }
  });

  $scope.$watch('user.password', function (o, n) {
    if (!_.isEqual(o, n)) {
      $scope.empty = true;
      $scope.change_password = false;
    }
  });
  self.validateEmail = function (email) {
    var re = /^([\w- ]+(?:\.[\w- ]+)*)@((?:[\w- ]+\.)*\w[\w- ]{0,66})\.([a-z]{2,6}(?:\.[a-z]{2})?)$/i;
    $scope.email_valid = {valid: re.test(email)};
    return re.test(email);
  };
  // *******  Init  *******
  $scope.init = function () {
    $scope.showTokenExpired = true;
    $scope.login_fail = { fail: false };
    $scope.email_valid = {valid: true};
    $scope.user = {};
    $scope.error = {};
    $scope.change_user = false;
    $scope.change_password = false;
    if (document.Error.flash[0] !== undefined) {
      $scope.flash = document.Error.flash[0][0];
    }
  };

  $scope.isEmailValid = function () {
    return !!$scope.email_valid.valid;
  };

  $scope.isAuthFailed = function () {
    return $scope.isEmailValid() && $scope.login_fail.fail;

  };
  $scope.cancelErrors = function () {
    if ($scope.login_fail.fail === true) {
      $scope.login_fail.fail = false;
    }

  };

  $scope.submit = function (event) {
    console.log("AAAAAAAAAAAAA");
    $scope.showTokenExpired = false;
    $scope.change_user = true;
    $scope.change_password = true;
    event.preventDefault();
    if (!$scope.user.name && !$scope.user.password) {
      $scope.user_empty = true;
      $scope.password_empty = true;
    } else {
      if (!self.validateEmail($scope.user.name)) {
        $scope.user_empty = true;
        $scope.password_empty = false;
      } else if (!$scope.user.password) {

        $scope.user_empty = false;
        $scope.password_empty = true;
      } else {
        $scope.user_empty = false;
        $scope.password_empty = false;
        var method = 'POST';
        var url = '/API/signin';
        $scope.data = {
          email: $scope.user.name,
          password: $scope.user.password
        };
        self.getPromise(method, url, { email: $scope.user.name, password: $scope.user.password,  remember_me: $scope.user.remember_me }).then(function (res) {
          if (res.data.tmp_password) {
            window.location.href = '/set_password';
          } else {
            window.location.href = '/signin';
          }
        }, function () {
          $scope.login_fail = { fail: 'true' };
        });
      }
    }
  };


  $scope.isFlash = function () {
    return $scope.flash === 'error';
  };
  $scope.linkToForgotPassword = function () {
    window.location.href = '/forgot_password';
  };

  $scope.onInputChange = function () {
    $scope.flash = false;
    $scope.email_not_valid  = {valid: false};
  };

  self.getPromise = function (method, url, params) {
    return $http({
      method: method,
      url: url,
      params: params
    });
  };
});


