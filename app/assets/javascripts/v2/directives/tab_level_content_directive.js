/*global angular, JST, _ , unused, window, document*/
angular.module('workships.directives').directive('tabLevelContent', function ($timeout, $location, $anchorScroll, dataModelService, analyzeMediator, StateService, tabService) {
  'use strict';
  return {
    restrict: 'E',
    template: JST['v2/tab_level_content'](),
    scope: {
      data: '='
    },
    link: function (scope) {
      // scope.should_update_word_cloud = false;
      var IMAGE_PATH = 'assets/flag_imgs/';
      var EXTENSION = '.png';
      scope.tabService = tabService;
      scope.graph_exists = false;
      scope.flag_exists = false;
      scope.measures_exists = false;
      scope.dataModelService = dataModelService;
      scope.data.product_type = window.__workships_bootstrap__.companies.product_type;
      if (!scope.data) { return; }
      scope.active = true;
      var rate_to_init_gauge = scope.data.gauge.rate;
      scope.data.gauge.rate = 0;
      scope.find_types_in_level = function (parent, algorithm_type) {
        return _.find(parent, { algorithm_type: algorithm_type});
      };

      scope.getDataForLevel = function (company_metric_id, type) {
        return dataModelService.getDataForLevel(company_metric_id, type);
      };

      scope.getAnalyzeCompanyMetric = function (company_metric_id, type) {
        var cm = dataModelService.getDataForLevel(company_metric_id, type);
        if (cm) { return cm.analyze_company_metric_id; }
      };

      scope.getGaugeParam = function (company_metric_id, param) {
        return dataModelService.getGaugeParam(company_metric_id, param);
      };

      scope.animate = function () {
        scope.data.gauge.rate =  rate_to_init_gauge;
      };

      scope.isGaugeEmpty = function (rate, metric_id) {
        var res = isNaN(rate) && (!metric_id || metric_id < 0);
        return res;
      };

      scope.jumpToExplore = function (emps, gauge_name, analyze_company_metric_id, algorithm_type) {
        var emps_flag = emps;
        analyzeMediator.resetChartState();
        analyzeMediator.setFlagData(emps_flag, gauge_name, tabService.current_tab, analyze_company_metric_id, algorithm_type);
        analyzeMediator.setSelected(StateService.get(tabService.current_tab + '_selected'), 'group');
        tabService.selectTab('Explore');
      };

      scope.jumpToExploreImage = function () {
        if (tabService.current_tab === 'Explore' || tabService.current_tab === 'Dashboard') { return; }
        return IMAGE_PATH + 'jump_to_' + tabService.current_tab + EXTENSION;
      };

      scope.topLevel = function (group_id) {
        if (!group_id) { return; }
        return dataModelService.getGroupBy(group_id).parent === null;
      };

      $timeout(scope.animate, 0);
      scope.gotoAnchor = function (x) {
        var newHash = x;
        var old = $location.hash();
        if ($location.hash() !== newHash) {
          if (x === 0) {
            $location.hash('');
          } else {
            $location.hash(x);
          }
          $anchorScroll();
          $location.hash(old);
        } else {
          $anchorScroll();
        }
      };
      // scope.$watch('data', function (n) {
      // }, true);
    }
  };
});
