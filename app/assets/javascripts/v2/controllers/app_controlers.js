/*globals angular , window, unused, _  */
angular.module('workships').controller('appController', function ($rootScope, $scope, $location, overlayBlockerService, $anchorScroll, dataModelService, currentUserService) {
  'use strict';
  /* istanbul ignore next */
  $scope.init = function () {
    $rootScope.VERSION = '1.4.4';
    $rootScope.show_sidebar = true;
    var setCurrentUser = function () {
      $scope.img_url = 'assets/logo.png'; //current_employee.img_url;
    };
    dataModelService.init();
    dataModelService.getEmployees().then(setCurrentUser);
  };

  /* istanbul ignore next */
  $scope.gotoTop = function (event) {
    unused(event);
    $location.hash('');
    $anchorScroll();
  };
  $scope.isBlocked = function () {
    return overlayBlockerService.isBlocked();
  };
  /* istanbul ignore next */
  $scope.data = window.__workships_bootstrap__;
  if ($scope.data && $scope.data.currentUser) {
    currentUserService.setCurrentUser($scope.data.currentUser);
    currentUserService.setShouldDisplayEmails($scope.data.displayEmails);
    if ($scope.data.companies.name === undefined) {
      //console.log(">>> ", $scope.data.companies);
      //$scope.current_company_name = _.find($scope.data.companies, {'id': $scope.data.currentUser.company_id}).name;
    }
  } else if ($scope.data) {
    $scope.current_company_name = $scope.data.companies.name;
  }

});
