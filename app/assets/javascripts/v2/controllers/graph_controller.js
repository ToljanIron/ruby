/*globals angular, document, JST, window, _ */
angular.module('workships')
  .config(['$logProvider', function($logProvider){
        $logProvider.debugEnabled(false);
  }])
  .controller('NewGraphCtrl', [
    '$scope', 'graphService', 'dataModelService', 'analyzeMediator', 'overlayBlockerService', 'StateService', '$timeout', 'pleaseWaitService', '$log',
    function ($scope, graphService, dataModelService, analyzeMediator, overlayBlockerService, StateService, $timeout, pleaseWaitService, $log) {
    'use strict';

    var self = this;

    var NETWORKS_METRICS;
    var GROUP_BY_LIST = [{
      id: 1,
      display: 'Structure',
      name: 'group_id',
      recursive: true
    }, {
      id: 2,
      display: 'Role type',
      name: 'role_type'
    }, {
      id: 3,
      display: 'Rank',
      name: 'rank'
    }, {
      id: 4,
      display: 'Gender',
      name: 'gender'
    }, {
      id: 5,
      display: 'Age',
      name: 'age_group'
    }, {
      id: 6,
      display: 'Formal',
      name: 'manager_id',
      recursive: true
    }, {
      id: 7,
      display: 'Office',
      name: 'office'
    }];

    function setSnapshots(snapshot_list) {
      $scope.snapshot_list = snapshot_list;
      if ($scope.selected.getSnapshotByIndex() === undefined) {
        $scope.selected.setSnapshotByIndex(0);
        $scope.snapshot_id = $scope.snapshot_list[0];
      } else {
        $scope.snapshot_id = $scope.snapshot_list[$scope.selected.getSnapshotByIndex()];
      }
    }

    function getSnapshots() {
      return dataModelService.getSnapshotList().then(setSnapshots);
    }

    function setGroups(groups_list) {
      $scope.groups = groups_list;
      var group_by_structure = _.find($scope.group_by_list, { name: 'group_id' });
      group_by_structure.values = _.map($scope.groups, function (group) {
        return { value: group.id, parent: group.parent, name: group.name, color: '#' + dataModelService.getColorsByName('group_id', group.id) };
      });
    }

    function setState() {
      // $log.debug("GC In setState()");
      var network_id = graphService.network_id;
      var tab_id = graphService.tab_id;
      if (network_id === undefined || _.isNull(network_id)) { network_id = $scope.analyze_data.networks[0].network_index; }
      if ($scope.tab === undefined || _.isNull(tab_id)) {
        $scope.tab =  $scope.tab_tree[Object.keys($scope.tab_tree)[$scope.tab_inx]];
      }
      var algo = _.find($scope.analyze_data.metrics, { measure_id: graphService.measure_id });
      $scope.network = $scope.findOrCreateNetwork(algo);
      if (!$scope.network) {
        $scope.network = $scope.analyze_data.networks[0];
      }
      $scope.measure = algo;
      $scope.measure_inx = (graphService.measure_inx !== -1 ? graphService.measure_inx : 0);
      if (algo === undefined) {
        $scope.measure = _.find($scope.analyze_data.metrics, { measure_name: $scope.tab[0] });
        $scope.network = $scope.findOrCreateNetwork($scope.measure);
      }
      $scope.group_by = _.find($scope.group_by_list, { id: graphService.group_by_id });
      $scope.layout = _.find($scope.layouts_list, { name: graphService.layout_name });
      $scope.measure_list = $scope.getMetricsList();
    }

    function setEmployeeNodeNames() {
      _.each($scope.measure.degree_list, function (node) {
        var employee = dataModelService.getEmployeeById(node.id);
        // _.where($scope.employees, { id: node.id })[0];
        if (employee === undefined) { return; }
        node.first_name = employee.first_name;
        node.last_name = employee.last_name;
        node.job_title = employee.job_title;
        node.email = employee.email;
      });
    }

    function normalizeName(name) {
      return name.toLowerCase().replace(/ /g, '_');
    }

    function setLevelFilters() {
      self.level_filters = _.map($scope.analyze_data.metrics, function (metric) {
        return normalizeName(metric.measure_name);
      });
    }

    function setEmployeeLevelFilterProperties() {
      _.each($scope.analyze_data.metrics, function (metric) {
        _.each(metric.degree_list, function (object) {
          var employee = dataModelService.getEmployeeById(object.id);
          // _.find($scope.employees, function (e) { return e.id === object.id; });
          if (!employee) { return; }
          employee[normalizeName(metric.measure_name)] = object.rate / 10;
        });
      });
    }

    function setAnalyzeData(data) {
      $log.debug("GC - setAnalyzeData() - set to true");
      graphService.update_graph = true;
      $scope.analyze_data = data;
      if ($scope.analyze_data.metrics.length === 0 || $scope.analyze_data.networks.length === 0) {
        $scope.problem_in_data = true;
        return;
      }
      _.each($scope.analyze_data.networks, function (network) { network.original_relation = _.cloneDeep(network.relation); });
      setState();
      setEmployeeNodeNames();
      setLevelFilters();
      setEmployeeLevelFilterProperties();
      return true;
    }

    function setGroupByFormalValuesByEmployees(managers) {
      var group_by = _.find($scope.group_by_list, { name: 'manager_id' });
      group_by.values = _.map(_.uniq(_.pluck(managers, 'manager_id')), function (manager_id) {
        var parent_record = _.find(managers, function (record) {
          return record.employee_id === manager_id;
        }) || { manager_id: null };
        var manager_employee = dataModelService.getEmployeeById(manager_id);
        return { value: manager_id, parent: parent_record.manager_id, name: manager_employee.group_name + ' (' + manager_employee.first_name + ')' || 'Unknown' };
      });
      var highest = _.filter(group_by.values, { parent: null });
      _.each(highest, function (gr) {
        gr.parent = 'NA';
      });
      group_by.values.push({
        value: 'NA',
        parent: null,
        name: 'NA'
      });
    }

    function setGroupByValuesByEmployees(group_by_name) {
      var color, group;
      var group_by = _.find($scope.group_by_list, { name: group_by_name });
      var groups_of_attribute = _.uniq(_.pluck($scope.employees, group_by_name));
      var attr_temp = [];
      _.each(groups_of_attribute, function (attr) {
        group = {};
        color = dataModelService.getColorsByName(group_by_name, attr) || '1f5d75';
        group.color = '#' + color;
        group.name = attr ||  'NA';
        group.value = attr || 'NA';
        group.parent = null;
        attr_temp.push(group);
      });
      group_by.values = attr_temp;
    }

    function setEmployees(data) {
      $scope.employees = data;
      var group_by_names = _.pluck($scope.group_by_list, 'name');
      _.each(group_by_names, function (name) {
        if (name === 'group_id') { return; }
        if (name === 'manager_id') {
          dataModelService.getManagers().then(setGroupByFormalValuesByEmployees);
        } else {
          setGroupByValuesByEmployees(name);
        }
      });
    }

    function getEmployees() {
      return dataModelService.getEmployees().then(setEmployees);
    }

    function removeParentGroups(list, selected_id) {
      var groups_list = _.cloneDeep(list);
      var selected_group = _.where(groups_list, { id: selected_id })[0];
      if (selected_group.parent === null) {
        return list;
      }
      groups_list = _.filter(groups_list, function (g) {
        return !_.contains(g.child_groups, selected_id);
      });
      selected_group.parent = null;
      selected_group.dad = undefined;
      return groups_list;
    }

    function updateAnalyze() {
      $log.debug("GC - In updateAnalyze()");
      var promise, f;
      if (!$scope.selected.id  || !$scope.snapshot_id || !$scope.selected.type || $scope.update_in_process) {
        return;
      }
      pleaseWaitService.on();
      $scope.update_in_process = true;
      $scope.problem_in_data = false;
      if ($scope.selected.type === 'pin') {
        promise = dataModelService.getPins();
        if ($scope.filter_group_ids) {
          $scope.filter_group_ids.splice(0, $scope.filter_group_ids.length);
        }
        f = function () {
          dataModelService.getAnalyze(-1, $scope.selected.id, $scope.snapshot_id.sid, $scope.selected.overlay_entity).then(setAnalyzeData).then($scope.updateData);
        };
      } else {
        promise = dataModelService.getGroups();
        f = function (groups_list) {
          groups_list = removeParentGroups(groups_list, $scope.selected.id);
          setGroups(groups_list);
          dataModelService.getAnalyze($scope.selected.id, -1, $scope.snapshot_id.sid, $scope.selected.overlay_entity)
            .then(setAnalyzeData)
            .then($scope.updateData);
        };
      }
      promise.then(f);
    }

    $scope.updateNetwork = function (item) {
      $scope.network = item;
      $scope.measure_list = $scope.getMetricsList();
      $scope.measure = $scope.measure_list[0];
      $scope.updateData(false, true);
    };

    $scope.updateAlgorithm = function (item) {
      $log.debug("GC - updateAglrithm() - saveCurrentChartState");
      analyzeMediator.saveCurrentChartState();
      $scope.removehighLighted();
      $scope.network = $scope.findOrCreateNetwork(item);
      $scope.updateData(false, true);
    };

    $scope.updateTab = function (tab_params) {
      $log.debug("GC - updateTab() - saveCurrentChartState");
      analyzeMediator.saveCurrentChartState();
      $scope.removehighLighted();
      $scope.measure_list = $scope.getMetricsToCurrentTab(tab_params);
      $scope.measure = $scope.measure_list[0];
      $scope.updateAlgorithm($scope.measure);
    };

    function findNetworksToCompose(network_ids_to_compose) {
      return _.filter($scope.analyze_data.networks, function (network) { return _.include(network_ids_to_compose, network.network_index); });
    }

    $scope.findOrCreateNetwork = function (item) {
      if (!item) { return; }
      var network = _.find($scope.analyze_data.networks, function (network) {
        return _.isEqual(network.network_bundle.sort(), item.network_ids.sort());
      });
      if (network) { return network; }
      var networks_to_compose = findNetworksToCompose(item.network_ids);
      network = graphService.createNewNetwork(networks_to_compose, item.network_ids);
      $scope.analyze_data.networks.push(network);
      return network;
    };

    $scope.updateMetric = function (item) {
      $scope.network = $scope.findOrCreateNetwork(item);
      $scope.measure = item;
      $scope.removehighLighted();
      $scope.updateData(true, false);
    };

    $scope.updateGroup = function (item) {
      $scope.group_by = item;
      $scope.updateData(true, false);
    };

    $scope.updateLayout = function (item) {
      $scope.layout = item;
      graphService.setLayout($scope.layout.name, false, function () {
        graphService.setSearch();
        $timeout(function () {
          graphService.setSearch(graphService.latest_search);
        }, 500, true);
      });
    };

    $scope.updateData = function (with_layout, metric_was_changed) {
      $log.debug("GC - In updateData()");
      if ($scope.problem_in_data) {
        $scope.update_in_process = false;
        return;
      }

      if (!$scope.measure) {
        if (!$scope.analyze_data.metrics) { return; }
        if (graphService.measure === null) {
          $scope.measure = _.find($scope.analyze_data.metrics, { measure_name: NETWORKS_METRICS[$scope.network.name][0] });
        } else {
          $scope.measure = graphService.measure;
        }
      }
      $scope.measure_inx = (graphService.measure_inx !== -1 ? graphService.measure_inx : 0);

      if (graphService.inHugeGraphState()) { $scope.group_by = $scope.group_by_list[0]; }
      setEmployeeNodeNames();
      $scope.setGroupBy();

      if ($scope.network.name === 'Communication Flow' && $scope.network.relation.length > 1000) {
        $scope.edge_sizes_range = { from: 5, to: 6 };
      } else {
        $scope.edge_sizes_range = { from: 0, to: 6 };
      }

      if ($scope.selected.getFlagData()) {
        if ($scope.snapshot_list) { $scope.snapshot_id = $scope.snapshot_list[0]; }
        graphService.measure_id = $scope.selected.flag_data.analyze_company_metric_id;
        var measure_name = _.find($scope.analyze_data.metrics, { measure_id: graphService.measure_id}).measure_name;
        $scope.tab =  _.find($scope.tab_tree, function (tab) { return _.include(tab, measure_name); });
      }
      // var overlay_types = dataModelService.overlay_snapshot_data === undefined ? [] : dataModelService.overlay_snapshot_data.overlay_entity_types;
      
      // graphService.setData($scope.measure, $scope.network, $scope.group_by.id, $scope.edge_sizes_range, $scope.selected.id, overlay_types || [], $scope.group_by);
      graphService.setData($scope.measure, $scope.network, $scope.group_by.id, $scope.edge_sizes_range, $scope.selected.id, $scope.group_by);

      graphService.setGroupBy($scope.group_by);
      // if (_.any($scope.selected.layers, { on: true })) {
      //   graphService.preSetOverlayData();
      // }

      graphService.handleBidirectionalLinks();

      if (metric_was_changed === true) {
        graphService.combineNodesIfNeeded();
      }

      if (graphService.isTabWasClicked()) {
        graphService.resetTabClicked();
        graphService.combineNodesIfNeeded();
      }

      graphService.unIsolateNode();
      StateService.set({name: 'network_graph', value: {
        selected_network: $scope.network.name,
        selected_metric: $scope.measure.measure_name,
        selected_group_by: $scope.group_by.display
      }});
      graphService.highLighted(analyzeMediator.getFlagData(), $scope.selected.id, $scope.snapshot_id.sid);
      if (with_layout) {
        graphService.setLayout($scope.layout.name);
      }
      if (graphService.inHugeGraphState()) {
        graphService.groupAll();
        var parent_node = _.find(graphService.getNodes(), { show: true });
        graphService.getEventHandlerOnDblClick(parent_node.id, parent_node.type);
      }
      $scope.update_in_process = false;
    };

    $scope.setGroupBy = function () {
      _.each($scope.measure.degree_list, function (node) {
        var node_employee = dataModelService.getEmployeeById(node.id);
        // _.find($scope.employees, { id: node.id });
        if (node_employee === undefined) {
          return;
        }
        var color = dataModelService.getColorsByName($scope.group_by.name, node_employee[$scope.group_by.name]) || '1f5d75';
        node.color = '#' + color;
        node.gender = node_employee.gender;
        node.group = node_employee[$scope.group_by.name];
        node.label = node_employee.first_name;
      });
    };

    self.setEmployeesNumber = function (n) {
      $scope.selected.filter.setEmployeesNumber(n);
    };

    $scope.setEdgeFilter = function () {
      $log.debug("In setEdgeFilter()");
      StateService.set({name: 'network_graph', value: {
        selected_edge: {
          from: $scope.edge_sizes_range.from,
          to: $scope.edge_sizes_range.to
        }
      }});
      graphService.filterByEdgeSize($scope.edge_sizes_range, false);
    };

    self.removeFilter = function (name, value) {
      $scope.selected.filter.remove(name, value);
    };

    self.addFilter = function (name, value) {
      $scope.selected.filter.add(name, value);
    };

    $scope.toggleLayoutMenu = function () {
      if (!overlayBlockerService.isElemDisplayed('layout-menu')) {
        overlayBlockerService.block('layout-menu');
      } else {
        overlayBlockerService.unblock();
      }
    };

    $scope.toggleSnapshotMenu = function () {
      if (!overlayBlockerService.isElemDisplayed('snapshot-menu')) {
        overlayBlockerService.block('snapshot-menu');
      } else {
        overlayBlockerService.unblock();
      }
    };

    $scope.$watch('selected.flag_data', function () {
      if (!$scope.selected.flag_data) { return; }
      if ($scope.snapshot_list) { $scope.snapshot_id = $scope.snapshot_list[0]; }
      var measure_name;
      graphService.measure_id = $scope.selected.flag_data.analyze_company_metric_id;
      var measure = _.find($scope.analyze_data.metrics, { measure_id: graphService.measure_id});
      if (measure) {
        measure_name =  measure.measure_name;
        $scope.tab =  _.find($scope.tab_tree, function (tab) { return _.include(tab, measure_name); });
        setState();
      }
      $scope.updateData(false, false);
      graphService.update_graph = true;
      if (!$scope.snapshot_id) { return; }
      graphService.highLighted(analyzeMediator.getFlagData(), $scope.selected.id, $scope.snapshot_id.sid);
    }, true);

    $scope.$watch('snapshot_id', function (n,o) {
      angular.noop(n);
      if ($scope.snapshot_id) {
        graphService.snapshot_id = $scope.snapshot_id.time;
        graphService.sid = $scope.snapshot_id.sid;
        graphService.closeCard();
        var index = _.indexOf($scope.snapshot_list, $scope.snapshot_id);
        $scope.selected.setSnapshotByIndex(index);
        if (o !== undefined) {
          updateAnalyze();
        }
      }
    }, true);

    $scope.changeSnapshot = function (snapshot) {
      $scope.snapshot_id = snapshot;
      $scope.removehighLighted();
      overlayBlockerService.unblock();
    };

    $scope.metricsByNetwork = function () {
      return function (measure) {
        return _.contains(NETWORKS_METRICS[$scope.network.name], measure.measure_name);
      };
    };

    $scope.metricsByTabs = function () {
      return function (measure) {
        return _.contains($scope.tab, measure.measure_name);
      };
    };

    $scope.getMetricsList = function () {
      if (!$scope.network) { return; }
      var res = _.filter($scope.analyze_data.metrics, function (metric) {
        return _.contains(NETWORKS_METRICS[$scope.network.name], metric.measure_name);
      });
      return res;
    };

    $scope.getMetricsToCurrentTab = function (tab_params) {
      var res = _.filter($scope.analyze_data.metrics, function (metric) {
        return _.contains(tab_params, metric.measure_name);
      });
      return res;
    };

    $scope.closeNetworkDropDown = function () {
      $scope.showPanel = false;
    };

    $scope.recentlyViewedWeeks = function () {
      return ['a', 'b', 'c', 'd', 'e', 'f'];
    };

    $scope.clickOnUnGroupAll = function () {
      if (graphService.inHugeGraphState()) { return; }
      graphService.ungroupAll();
      $scope.ungroupAllNodes = true;
      $scope.groupAllNodes = false;
    };

    $scope.init = function () {
      $log.debug("GC - init() - setting to true");
      graphService.update_graph = true;
      pleaseWaitService.on();
      $scope._ = _;

      $scope.analyze_data = { networks: [], measures: [] };
      $scope.tab_inx = (graphService.tab_inx !== -1 ? graphService.tab_inx : 0);
      graphService.tab_inx = $scope.tab_inx;
      $scope.measure_inx = (graphService.measure_inx !== -1 ? graphService.measure_inx : 0);

      if (graphService.tab_tree === null) {
        dataModelService.getAnalyzeTree().then(function (data) {
          $scope.tab_tree  = data;
          graphService.tab_tree = $scope.tab_tree;
          NETWORKS_METRICS = data;
          graphService.network_metrics = NETWORKS_METRICS;
          $scope.tab =  $scope.tab_tree[Object.keys($scope.tab_tree)[$scope.tab_inx]];
        });
      } else {
        $scope.tab_tree = graphService.tab_tree;
        $scope.tab =  $scope.tab_tree[Object.keys($scope.tab_tree)[$scope.tab_inx]];
        NETWORKS_METRICS = graphService.network_metrics;
      }

      $scope.graphService = graphService;
      $scope.overlay_blocker_service = overlayBlockerService;

      $scope.chosen_settings_state = 'data';
      $scope.groupAllNodes = false;
      $scope.ungroupAllNodes = false;
      $scope.selected = analyzeMediator;
      $scope.in_first_time = true;
      $scope.edge_sizes_range = { from: 0, to: 6 };

      $scope.layouts_list = [{ name: 'standard' }, { name: 'advanced' }];
      $scope.layout = $scope.layouts_list[0];

      $scope.group_by_list = GROUP_BY_LIST;
      $scope.group_by = $scope.group_by_list[0];

      getSnapshots().then(getEmployees).then(updateAnalyze);
      $scope.selected_week = { name: '01-01-2001' };
    };

    function updateEmpsAndOverlay(value) {
      if (value === undefined) {
        updateAnalyze();
        return;
      }
      var entitiy_group_ids_of_showing, entity_ids_of_showing;
      if (value === null) {
        entitiy_group_ids_of_showing = dataModelService.fetchGroupIdsFromOverlayEntity(analyzeMediator.shown_overlay_groups);
        entity_ids_of_showing = analyzeMediator.entity_ids_of_showing || [];
      } else {
        entitiy_group_ids_of_showing = value.type === 'group' ? [value.id] : [];
        entity_ids_of_showing = value.type === 'id' ? [value.id] : [];
      }
      //dataModelService.getOverlaySnapshotData(entitiy_group_ids_of_showing, entity_ids_of_showing, $scope.selected.id, graphService.sid, true).then(function () {
      //  pleaseWaitService.on();
      //  updateAnalyze();
      //  graphService.preSetOverlayData();
      //});
    }

    $scope.$watch('tab_inx', function(n) {
        graphService.tab_inx = n;
    });

    $scope.$watch('measure_inx', function(n) {
        graphService.measure_inx = n;
    });

    $scope.$watch('measure', function(n) {
        graphService.measure = n;
    });

    $scope.$watch('[selected.id, selected.type]', function (n,o) {
      if (o[0] === undefined  || n === o) { return; }
      updateEmpsAndOverlay($scope.selected.overlay_entity);
    });

    $scope.$watch('selected.overlay_entity', function (nvalue, ovalue) {
      if (ovalue === undefined && nvalue === undefined) { return; }
      updateEmpsAndOverlay(nvalue);
    });

    $scope.$watch('selected.toogle_on_overlay', function (value) {
      if (value === undefined) { return; }
      $scope.updateData(false, false);
    });

    $scope.$on('$destroy', function () {
      graphService.latest_search = null;
      graphService.edge_interval = null;
      graphService.click_to_isolate = null;
    });
  }]);
