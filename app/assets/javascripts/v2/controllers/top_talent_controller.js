/*globals angular , window, unused, _  */
angular.module('workships').controller('topTalentController', function ($scope, dataModelService, dashboradMediator, tabService) {
  'use strict';

  function updateData(rest) {
    // $scope.data_model.getMeasures($scope.selected.id, -1, true).then(function (response) {
    // });
    $scope.data_model.getMeasures($scope.selected.id, -1, rest);
    $scope.data_model.getFlags($scope.selected.id, -1, rest);
  }

  $scope.init = function () {
    $scope.tabService = tabService;
    $scope.show_page = false;
    $scope.selected = dashboradMediator;
    // var relevant_tab_tree = dataModelService.ui_levels[0].children;
    // $scope.tab_levels = relevant_tab_tree;
    function onSucss() {
      $scope.tab_levels = _.sortBy(dataModelService.getUiLevel(1), 'display_order');
      // $scope.tab_levels = dataModelService.getUiLevel(1);
      $scope.selected_tab = _.find($scope.tab_levels, function (tl) { return tl.id === tabService.subTabs['Top Talent']; }) || $scope.tab_levels[0];
      tabService.setSubTab('Top Talent', $scope.selected_tab.id);
      $scope.show_page = true;
    }
    dataModelService.getUiLevels().then(onSucss);
    // $scope.data_model = dataModelService;
  };
  $scope.$parent.restart = function () {
    $scope.init();
  };
  $scope.changeTab = function (selected) {
    var selected_id = tabService.setSubTab('Top Talent', selected.id);
    $scope.selected_tab = _.find($scope.tab_levels, function (tl) { return tl.id === selected_id; });
  };

});

