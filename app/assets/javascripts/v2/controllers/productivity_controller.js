/*globals angular , window, unused, _  */
angular.module('workships').controller('productivityController', function ($scope, dashboradMediator, dataModelService, tabService) {
  'use strict';

  function updateData() {
    // $scope.data_model.getMeasures($scope.selected.id, -1, true).then(function (response) {
    // });
    $scope.data_model.getMeasures($scope.selected.id, -1, true);
    $scope.data_model.getFlags($scope.selected.id, -1, true);
    $scope.data_model.getGauges($scope.selected.id, -1, true);
  }
  $scope.init = function () {
    // var relevant_tab_tree = dataModelService.ui_levels[2].children;
    // $scope.tab_levels = relevant_tab_tree;
    // $scope.tab_levels = [{
    //   name: 'time utiliztion',
    //   main_gague: {  min_range : 0, max_range: 100, min_range_wanted: 0,
    //             max_range_wanted: 32, rate: 30, radius: 120, title: '',
    //             background_color: 'rgba(237,30,121,0.16)', wanted_area_color: 'rgb(237,30,121)'},
    //   id: 1,
    //   level_3: [{
    //     name: 'time spent on emails',
    //     gauge:  {  min_range : 1, max_range: 30, min_range_wanted: 12,
    //             max_range_wanted: 22, rate: 10, radius: 80, title: '',
    //             background_color: 'rgba(237,30,121,0.16)', wanted_area_color: 'rgb(237,30,121)'},
    //     level_4: [{
    //       title: 'no of emails',
    //       type: '50-20000'
    //     }, {
    //       title: 'average subject length',
    //       type: '1-15'
    //     }, {
    //       title: 'average mail length',
    //       type: '5-152',
    //     }, {
    //       title: 'proportion of email chains',
    //       type: '0-100',
    //     }, {
    //       title: 'average email chain length',
    //       type: '0-100',
    //     }]
    //   }, {
    //     name: 'email specificity',
    //     gauge: {  min_range : 0, max_range: 100, min_range_wanted: 12,
    //             max_range_wanted: 42, rate: 60, radius: 80, title: '',
    //             background_color: 'rgba(237,30,121,0.16)', wanted_area_color: 'rgb(237,30,121)'},
    //     level_4: [{
    //       title: 'average mailing list size',
    //       type: '2-20'
    //     }, {
    //       title: 'proportion of mails in mailing list',
    //       type: '0-100'
    //     }, {
    //       title: 'proportion of relays',
    //       type: '0-100',
    //     }, {
    //       title: 'proportion of sinks',
    //       type: '0-100'
    //     }, {
    //       title: 'proportion of emails chains',
    //       type: '0-100'
    //     }, {
    //       title: 'email focus',
    //       type: 'metric',
    //       metric: {},
    //     }]
    //   }, {
    //     name: 'time spent on meetings',
    //     gauge: {  min_range : 1, max_range: 30, min_range_wanted: 5,
    //             max_range_wanted: 25, rate: 17, radius: 80, title: '',
    //             background_color: 'rgba(237,30,121,0.16)', wanted_area_color: 'rgb(237,30,121)'},
    //     level_4: [{
    //       title: 'proportion time spent on meeting',
    //       type: '1-45',
    //     }, {
    //       title: 'average no of attendees',
    //       type: '2-15'
    //     }, {
    //       title: 'proportion of meetings condoucted elsewhere',
    //       type: '0-100'
    //     }]
    //   }, {
    //     name: 'meeting specificity',
    //     gauge: {  min_range : 0, max_range: 100, min_range_wanted: 23,
    //             max_range_wanted: 93, rate: 17, radius: 80, title: '',
    //             background_color: 'rgba(237,30,121,0.16)', wanted_area_color: 'rgb(237,30,121)'},
    //     level_4: [{
    //       title: 'proportion meeting memvers involved in emails with similar keywords',
    //       type: '0-100'
    //     }]
    //   }]
    // }, {
    //   name: 'workload heterogeneity',
    //   main_gague: {  min_range : 0, max_range: 100, min_range_wanted: 29,
    //             max_range_wanted: 89, rate: 74, radius: 120, title: '',
    //             background_color: 'rgba(237,30,121,0.16)', wanted_area_color: 'rgb(237,30,121)'},
    //   id: 2,
    //   level_3: [{
    //     name: 'hidden unemployment',
    //     gauge: {  min_range : 0, max_range: 100, min_range_wanted: 29,
    //             max_range_wanted: 60, rate: 74, radius: 80, title: '',
    //             background_color: 'rgba(237,30,121,0.16)', wanted_area_color: 'rgb(237,30,121)'},
    //     level_4: [{
    //       title: 'no of isolates',
    //       type: '0-50 (uppward limit depends on company size)'
    //     }, {
    //       title: 'no of sinks',
    //       type: '0-43 (uppward limit depends on company size)',
    //     }, {
    //       title: 'proportion manager never in meeting',
    //       type: '0-100'
    //     }]
    //   }, {
    //     name: 'hidden overemployment',
    //     gauge: {  min_range : 0, max_range: 100, min_range_wanted: 35,
    //             max_range_wanted: 78, rate: 64, radius: 80, title: '',
    //             background_color: 'rgba(237,30,121,0.16)', wanted_area_color: 'rgb(237,30,121)'},
    //     level_4: [{
    //       title: 'no of bottlenecks',
    //       type: '0-20 (uppward limit depends on company size)'
    //     }, {
    //       title: 'proportion mailing lists',
    //       type: '?',
    //     }]
    //   }]
    // }];
    $scope.tabService = tabService;
    $scope.show_page = false;
    $scope.selected = dashboradMediator;
    // var relevant_tab_tree = dataModelService.ui_levels[0].children;
    // $scope.tab_levels = relevant_tab_tree;
    function onSucss() {
      $scope.tab_levels = _.sortBy(dataModelService.getUiLevel(2), 'display_order');
      // $scope.tab_levels = dataModelService.getUiLevel(2);
      $scope.selected_tab = _.find($scope.tab_levels, function (tl) { return tl.id === tabService.subTabs.Productivity; }) || $scope.tab_levels[0];
      tabService.setSubTab('Productivity', $scope.selected_tab.id);
      $scope.show_page = true;
    }
    dataModelService.getUiLevels().then(onSucss);
    // $scope.data_model = dataModelService;
    // $scope.selected_tab = $scope.tab_levels[0];
    // $scope.selected_tab = $scope.tab_levels[0];
    // $scope.selected = dashboradMediator;
    // $scope.data_model = dataModelService;
    // $scope.selected_tab = $scope.tab_levels[0];
    // $scope.$watch('[selected.id, selected.type]', function () {
    //   updateData();
    // });
  };

  $scope.$parent.restart = function () {
    $scope.init();
  };
  $scope.changeTab = function (selected) {
    var selected_id = tabService.setSubTab('Productivity', selected.id);
    $scope.selected_tab = _.find($scope.tab_levels, function (tl) { return tl.id === selected_id; });
  };

});
