/*globals angular, unused, goBack */
angular.module('workships-mobile').controller('questionnaireTabController', function ($scope) {
  'use strict';

  $scope.init = function (status) {
    $scope.status = status;
    $scope.UNSENT = 0;
    $scope.SEND_REQUEST = 1;
    $scope.SENT = 2;
    $scope.RESEND_REQUEST = 3;
  };

  $scope.rollbackStatus = function () {
    $scope.status--;
    if ($scope.status < 0) {
      goBack();
    }
  };

  $scope.requestSendquestionnaire = function () {
    $scope.status = $scope.SEND_REQUEST;
  };

  $scope.confirmSendquestionnaire = function () {
    $scope.status = $scope.SENT;
  };

  $scope.requestResendquestionnaire = function () {
    $scope.status = $scope.RESEND_REQUEST;
  };
});