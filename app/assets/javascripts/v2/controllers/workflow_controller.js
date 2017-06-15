/*globals angular , window, unused, _  */
angular.module('workships').controller('workflowController', function ($scope, dashboradMediator, dataModelService, tabService, pleaseWaitService) {
  'use strict';

  $scope.init = function () {
    $scope.tabService = tabService;
    $scope.show_page = false;
    $scope.selected = dashboradMediator;

    function onSucss() {
      $scope.tab_levels = _.sortBy(dataModelService.getUiLevel(0), 'display_order');
      $scope.selected_tab = _.find($scope.tab_levels, function (tl) { return tl.id === tabService.subTabs.Workflow; }) || $scope.tab_levels[0];
      tabService.setSubTab('Workflow', $scope.selected_tab.id);
      $scope.show_page = true;
    }
    dataModelService.getUiLevels().then(onSucss);
  };

  $scope.$parent.restart = function () {
    $scope.init();
  };

  $scope.changeTab = function (selected) {
    var selected_id = tabService.setSubTab('Workflow', selected.id);
    $scope.selected_tab = _.find($scope.tab_levels, function (tl) { return tl.id === selected_id; });
  };

});

