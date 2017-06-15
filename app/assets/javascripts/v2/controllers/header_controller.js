/*globals angular , document, window, unused, _, $  */
angular.module('workships').controller('headerController', function ($scope, tabService) {
  'use strict';

  var TABSIZE = 85;
  var SPACEFORLOGO = 300;
  var tService;

  $scope.canGoRight = function () {
    return $scope.tabDims.rightSeenTab < 5;
  };

  $scope.canGoLeft = function () {
    return $scope.tabDims.leftSeenTab > 0;
  };

  $scope.moveSliderLeft = function () {
    if ($scope.tabDims.leftSeenTab > 0) {
      $scope.tabDims.leftSeenTab--;
      $scope.tabDims.rightSeenTab--;
    }
  };

  $scope.moveSliderRight = function () {
    if ($scope.tabDims.rightSeenTab < 5) {
      $scope.tabDims.leftSeenTab++;
      $scope.tabDims.rightSeenTab++;
    }
  };

  $scope.$on('resize', function () {
    var tabModel = tService.changeTab($scope.currTabCount, window.innerWidth, $scope.tabDims.leftSeenTab);
    $scope.currTabCount  = tabModel.currTabCount;
    $scope.tabDims.leftSeenTab  = tabModel.leftSeenTab;
    $scope.tabDims.rightSeenTab = tabModel.rightSeenTab;

    var newGetTabWidth = {'width': ($scope.currTabCount * TABSIZE) + 90 + 'px'};
    if (newGetTabWidth !== $scope.tabDims.getTabWidth) {
      $scope.tabDims.getTabWidth = newGetTabWidth;
    }
    var newGetTabWindowWidth = {'width': ($scope.currTabCount * TABSIZE) + 'px'};
    if (newGetTabWindowWidth !== $scope.tabDims.getTabWindowWidth) {
      $scope.tabDims.getTabWindowWidth = newGetTabWindowWidth;
    }
  });

  $scope.goToDefaultTab = function () {
    switch(window.__workships_bootstrap__.companies.product_type) {
      case 'questionnaire_only':
        tService.selectTab('Collaboration');
        break
      default:
        tService.selectTab('Dashboard');
    }
  };

  $scope.init = function () {
    tService = tabService;
    $scope.tabCount = 8;
    var tabDims = {};
    tabDims.leftSeenTab = 0;
    $scope.screen_size = {
      height: window.innerHeight,
      width:  window.innerWidth
    };
    $scope.currTabCount = Math.floor(($scope.screen_size.width - SPACEFORLOGO) / TABSIZE);
    $scope.showMiniHeader = false;

    tabDims.rightSeenTab = $scope.currTabCount - 1;
    $scope.tabDims = tabDims;
    switch(window.__workships_bootstrap__.companies.product_type) {
      case 'questionnaire_only':
        $scope.page_title_name = 'Collaboration';
        break
      default:
        $scope.page_title_name = 'Dashboard';
    }
  };
});
