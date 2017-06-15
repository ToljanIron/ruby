/*globals angular, _*/
angular.module('workships.services').factory('analyzeMediator', function (FilterFactoryService) {
  'use strict';
  var selected = {};
  var first_time = true;
  var filter_init = false;
  var chart = null;
  var orig_chart = null;
  selected.layouts = [{label: 'Radial', value: 1}, {label: 'Standard', value: 2}];
  selected.layout = selected.layouts[0];
  selected.isolate = {isolate: false};
  selected.group_measures = {};
  selected.filter = FilterFactoryService.create();
  selected.init = function (id) {
    selected.type = 'group';
    selected.id = id;
    selected.selected_tab = 1;
    selected.filter_list = [];
    first_time = false;
    chart = null;
  };
  selected.setSelected = function (id, type) {
    selected.type = type;
    selected.id = id;
  };

  selected.getSelectedId = function() {
    return selected.id;
  };

  selected.inFirstTime = function () {
    return first_time;
  };

  selected.clearChart = function () {
    if (chart && _.isFunction(chart.clear)) {
      chart.clear();
      chart = null;
    }
  };

  selected.isFilterInit = function () {
    return filter_init;
  };

  selected.saveCurrentChartState = function() {
    var keylinesChart = selected.getChart();
    selected.setChartState(keylinesChart);
  };

  selected.resetChartState = function() {
    chart = null;
    selected.chartState = chart;
  };

  selected.setChartState = function (new_chart) {
    if (chart && chart !== new_chart && _.isFunction(chart.clear)) {
      chart.clear();
    }
    chart = new_chart.serialize();
    selected.chartState = chart;
  };

  selected.getChartState = function () {
    return chart;
  };

  selected.setChart = function(ochart) {
    orig_chart = ochart;
  };

  selected.getChart = function() {
    return orig_chart;
  };

  selected.initFilter = function () {
    filter_init = true;
  };

  selected.isNewGraph = function () {
    return (chart === null);
  };
  /* istanbul ignore next */
  selected.setGroupByIndex = function (index) {
    selected.group_by_index = index;
  };
  /* istanbul ignore next */
  selected.getGroupByIndex = function () {
    return selected.group_by_index;
  };
  /* istanbul ignore next */
  selected.getMeasureByIndex = function () {
    return selected.measure_by_index;
  };
  /* istanbul ignore next */
  selected.setMeasureByIndex = function (index) {
    selected.measure_by_index = index;
  };
  /* istanbul ignore next */
  selected.getNetworkByIndex = function () {
    return selected.network_by_index;
  };
  /* istanbul ignore next */
  selected.setNetworkByIndex = function (index) {
    selected.network_by_index = index;
  };
  /* istanbul ignore next */
  selected.setSnapshotByIndex = function (index) {
    selected.snapshot_by_index = index;
  };
  /* istanbul ignore next */
  selected.getSnapshotByIndex = function () {
    return selected.snapshot_by_index;
  };

  /* istanbul ignore next */
  selected.setFlagData = function (emp_ids, flag_name, current_tab, analyze_company_metric_id, algorithm_type, company_metric_id) {
    selected.flag_data = {emp_ids: emp_ids, flag_name: flag_name, flag_tab: current_tab, jump_to: true, analyze_company_metric_id: analyze_company_metric_id, algorithm_type: algorithm_type, company_metric_id: company_metric_id};
  };

  /* istanbul ignore next */
  selected.getFlagData = function () {
    return selected.flag_data;
  };

  selected.toggleAllLayers = function () {
    _.each(selected.layers, function (layer) {
      _.each(layer.values, function (v, k) {
        angular.noop(v);
        if (_.contains(selected.shown_overlay_groups, k.split(' (')[0])) {
          layer.values[k] = true;
        }
      });
    });
  };

  return selected;
});
