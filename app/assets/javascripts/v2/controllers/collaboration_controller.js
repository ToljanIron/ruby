/*globals angular , window, unused, _  */
angular.module('workships').controller('collaborationController', function ($scope, dashboradMediator, dataModelService, tabService, pleaseWaitService) {
  'use strict';

  $scope.init = function () {
    $scope.tabService = tabService;
    $scope.show_page = false;
    $scope.selected = dashboradMediator;
    function onSucss() {
      $scope.tab_levels = _.sortBy(dataModelService.getUiLevel(3), 'display_order');
      $scope.selected_tab = _.find($scope.tab_levels, function (tl) { return tl.id === tabService.subTabs.Collaboration; }) || $scope.tab_levels[0];
      tabService.setSubTab('Collaboration', $scope.selected_tab.id);
      $scope.show_page = true;
    }
    dataModelService.getUiLevels().then(onSucss);
  };

  $scope.$parent.restart = function () {
    $scope.init();
  };

  function transformCommunicationDynamics(data) {
    return _.map(data, function (o) {
      var name;
      if (o.id === 0) {
        name = 'External';
      } else if (o.id === -1) {
        name = 'Other';
      } else {
        name = o.id === $scope.selected.id ? 'Internal' : dataModelService.getGroupBy(o.id).name;
      }
      return { name: name, size: o.measure };
    });
  }

  function setCommunicationDynamics() {
    $scope.selected_tab.group_id = $scope.selected.id;
    var communication_dynamics = _.find(dataModelService.mesures, { name: 'communication_dynamics' });
    if (!communication_dynamics || dataModelService.getGroupBy($scope.selected.id).level === 0) {
      $scope.selected_tab.list_of_sectors = undefined;
      return;
    }
    var last_snapshot_data = _.last(_.values(communication_dynamics.snapshots));
    $scope.selected_tab.list_of_sectors = transformCommunicationDynamics(last_snapshot_data);
  }

  function getAndSetCommunicationDynamics() {
    dataModelService.getMeasures($scope.selected.id, -1, true).then(function () {
      setCommunicationDynamics();
    });
  }

  $scope.changeTab = function (selected) {
    var selected_id = tabService.setSubTab('Collaboration', selected.id);
    $scope.selected_tab = _.find($scope.tab_levels, function (tl) { return tl.id === selected_id; });
    if ($scope.selected_tab.name !== 'Communication dynamics') { return; }
    getAndSetCommunicationDynamics();
  };

  $scope.$watch('selected.id', function () {
    if (!$scope.selected_tab) { return; }
    getAndSetCommunicationDynamics();
  });
});

