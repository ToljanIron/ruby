/*globals angular , $ ,  window , KeyLines ,_ , unused */
angular.module('workships').controller('forgotPassword', function ($scope, $http) {
  'use strict';
  //*******  Watch *******
  $scope.$watch('user.email', function (o, n) {
    if (!_.isEqual(o, n)) {
      $scope.change_email = false;
      $scope.error.email = false;
    }
  });

  $scope.init = function () {
    $scope.login_fail = { fail: false };
    $scope.email_valid = { valid: true };
    $scope.user = {};
    $scope.error = {};
    $scope.error.email = true;
    $scope.change_email = false;
  };
  function validateEmail(email) {
    var re = /^([\w- ]+(?:\.[\w- ]+)*)@((?:[\w- ]+\.)*\w[\w- ]{0,66})\.([a-z]{2,6}(?:\.[a-z]{2})?)$/i;
    return re.test(email);
  }
  function getPromise(method, url, params) {
    return $http({
      method: method,
      url: url,
      params: params
    });
  }
  $scope.submit = function (event) {
    var method = 'POST';
    var url = '/user_forgot_password';
    $scope.change_email = true;
    event.preventDefault();
    if (!validateEmail($scope.user.email)) {
      $scope.email_valid = { valid: false };
      $scope.login_fail = { fail: false };
    } else {
      $scope.email_valid = {valid: true};
      getPromise(method, url, { data: $scope.user.email }).then(function (res) {
        $scope.login_fail = { fail: true };
        if (res.error) {
          return;
        }
      }, function () {
        $scope.login_fail = { fail: true };
      });
    }
  };

  $scope.isEmailValid = function () {
    return !!$scope.email_valid.valid;
  };

  $scope.isAuthFailed = function () {
    return $scope.login_fail.fail;

  };

  $scope.linkToSignin = function () {
    window.location.href = '/signin';
  };

});