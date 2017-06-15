/*globals angular, alert, _*/

angular.module('workships.services').factory('graphService', function (dataModelService, combineService, StateService, tabService, $timeout, analyzeMediator) {
  'use strict';

  var graphService = {};
  var open_card = {};
  var cached_layouts = {};
  var nodes, links, group_by, search, filtered_ids, singles_length, isolated, isolated_group, previous_limits, touched_overlay_combos = [], combined_groups = [];
  var all_links, all_nodes;
  var link_color = '#f2d4d2';
  var FLAG = 2;
  graphService.group_by_id = 1;
  graphService.layout_name = 'standard';
  graphService.tab_inx = -1;
  graphService.tab_tree = null;
  graphService.network_metrics = null;
  graphService.measure_inx = -1;
  graphService.measure     = null;


  var group_by_list = [{
    id: 1,
    display: 'Structure'
  }, {
    id: 2,
    display: 'Role type'
  }, {
    id: 3,
    display: 'Rank'
  }, {
    id: 4,
    display: 'Gender'
  }, {
    id: 5,
    display: 'Age'
  }, {
    id: 6,
    display: 'Formal'
  }, {
    id: 7,
    display: 'Office'
  }];

  graphService.tabWasClicked = false;

  graphService.setTabToClicked = function() {
    graphService.tabWasClicked = true;
  };

  graphService.resetTabClicked = function() {
    graphService.tabWasClicked = false;
  };

  graphService.isTabWasClicked = function() {
    return graphService.tabWasClicked;
  };

  function setConditions(filter, group_filter) {
    var conditions = filter,
        overlay_entity_conditions;
    conditions.group_id = group_filter;
    if (!_.isEmpty(conditions.rank) || !_.isEmpty(conditions.rank_2)) {
      conditions.rank = _.union(conditions.rank, conditions.rank_2);
    }
    overlay_entity_conditions = {
      overlay_entity_group_name: _.union(conditions.external_domains, conditions.keywords),
      keyword_name: conditions.keywords_names,
      id: conditions.external_id || {}
    };
    return { employee: _.omit(conditions, ['external_domains', 'external_id', 'keywords', 'keywords_names']), overlay: overlay_entity_conditions };
  }

  function includeOverlay(layers) {
    _.each(layers, function (layer) {
      var layer_entities = _.filter(dataModelService.overlay_snapshot_data.overlay_entities, { overlay_entity_type_name: layer.title });
      _.each(layer_entities, function (entity) {
        entity.active = layer.on;
      });
    });
  }

  graphService.preSetOverlayData = function () {
    includeOverlay(analyzeMediator.layers);
    //var entitiy_group_ids_of_showing = dataModelService.fetchGroupIdsFromOverlayEntity(analyzeMediator.shown_overlay_groups);
    var _network = _.filter(dataModelService.overlay_snapshot_data.network, { snapshot_id: graphService.sid });
    var _nodes = _.filter(dataModelService.overlay_snapshot_data.overlay_entities, function (n) {
      return (n.active === true || n.active === 't')
             && (_.contains(analyzeMediator.shown_overlay_groups, n.overlay_entity_group_name)
               || n.overlay_entity_type_name === 'keywords' && analyzeMediator.filter.getFilter().keywords_names && _.contains(_.keys(analyzeMediator.filter.getFilter().keywords_names), n.name))
             && _.any(_network, function (l) {
              return (l.from_type === 'overlay_entity' && l.from_id === n.id
                        && _.any(nodes, { type: 'single', id: l.to_id }))
                     || (l.to_type === 'overlay_entity' && l.to_id === n.id
                        && _.any(nodes, { type: 'single', id: l.from_id })); });
    });

    // If there are no connections then at least add the keywords themselves to avoid having a blank screen upon drill-in
    //   since it may confuse the user.
    if (_nodes.length === 0 && tabService.drillDownOriginIsOverlay()) {
      _nodes = _.filter(dataModelService.overlay_snapshot_data.overlay_entities, function (n) {
      return (n.active === true || n.active === 't')
             && (_.contains(analyzeMediator.shown_overlay_groups, n.overlay_entity_group_name)
               || n.overlay_entity_type_name === 'keywords' && analyzeMediator.filter.getFilter().keywords_names && _.contains(_.keys(analyzeMediator.filter.getFilter().keywords_names), n.name))
      });}

    graphService.setOverlayData(_nodes, _network);
    graphService.setFilter(analyzeMediator.filter.getFiltered(), analyzeMediator.filter.getFilterGroupIds());
    tabService.setDrillDownOriginNone();
  };

  graphService.setFilter = function (filter, group_filter) { // _TODO: fix after the filter is fixed
    // if (!$scope.groups) { return; }
    var ids, overlay_ids,
        conditions = setConditions(filter, group_filter),
        overlay_entity_conditions = conditions.overlay;
    conditions = conditions.employee;
    function conditionsEmpty(conditions) {
      return _.isEmpty(conditions)
             || (_.keys(conditions).length === 1
                && (conditions.group_id
                   && (_.isEmpty(conditions.group_id)
                      || conditions.group_id.length === dataModelService.groups.length))
                   || _.values(conditions)[0] === undefined);

    }
    function groupConditionsEmpty() {
      return _.isEmpty(conditions.group_id);
    }
    function valueInCriteria(value, key) {
      return _.contains(conditions[key], value) || _.contains(conditions[key], String(value));
    }
    function keyIsLevelAndValueIsInRange(value, key) {
      return _.contains(self.level_filters, key) && _.inRange(value, conditions[key][0], conditions[key][1]);
    }
    function validPair(value, key) {
      return valueInCriteria(value, key) || keyIsLevelAndValueIsInRange(value, key);
    }

    if (conditionsEmpty(conditions)) {
      ids = _.pluck(dataModelService.employees, 'id');
    } else {
      if (groupConditionsEmpty()) {
        conditions.group_id = _.pluck(dataModelService.groups, 'id');
      }
      ids = _.pluck(_.filter(dataModelService.employees, function (employee) {
        var result = true;
        _.each(employee, function (value, key) {
          if (_.has(conditions, key)) {
            result = result && validPair(value, key);
          }
        });
        return result;
      }), 'id');
    }
    overlay_ids = [];
    if (conditionsEmpty(overlay_entity_conditions) || !dataModelService.overlay_snapshot_data) {
      // if (!$scope.overlay_snapshot_data) { return; }
      overlay_ids = []; // _.pluck($scope.overlay_snapshot_data.overlay_entities, 'id');
    } else {
      overlay_ids = _(dataModelService.overlay_snapshot_data.overlay_entities).filter(function (entity) {
        return _.all(overlay_entity_conditions, function (v, k) {
          if (k === 'overlay_entity_group_name' || k === 'keyword_name') {
            v = _.map(overlay_entity_conditions.overlay_entity_group_name, function (name) { return name.split(' (')[0]; });
            return _.include(v, entity.overlay_entity_group_name) || entity.overlay_entity_type_name === 'keywords' && _.include(overlay_entity_conditions.keyword_name, entity.name);
          }
          return (_.isEmpty(v) && _.isEmpty(conditions.id)) || _.include(v, String(entity[k]));
        });
      }).pluck('id').value();
    }
    var overlayLen = dataModelService.overlay_snapshot_data === undefined ? 0 : dataModelService.overlay_snapshot_data.overlay_entities.length;
    graphService.setFilterByNodesIds({ employee: ids, overlay: overlay_ids }, dataModelService.employees.length + overlayLen);
  };

  graphService.getOpenCard = function () {
    return open_card;
  };

 function createNewNode(id, type, rate, group) {
    var new_node = {
      id: id,
      type: type,
      rate: rate,
      group: group
    };
    return new_node;
  }

  function createNewLink(from_id, from_type, to_id, to_type, weight) {
    var new_link = {
      from_id: from_id,
      from_type: from_type,
      to_id: to_id,
      to_type: to_type,
      way_arr: false,
      weight: weight
    };
    return new_link;
  }

  // function nodesMatch(node1, node2) {
  //   return node1.id === node2.id && node1.type === node2.type;
  // }

  function nodeIsOrigin(node, link) {
    if (!node) { return false; }
    if (link.from_id === node.id && link.from_type === node.type) {
      return true;
    }
  }

  function nodeIsDestination(node, link) {
    if (!node) { return false; }
    if (link.to_id === node.id && link.to_type === node.type) {
      return true;
    }
  }

  function linkOriginNode(link) {
    return combineService.getLinkOriginNode(link);
  }

  function linkDestinationNode(link) {
    return combineService.getLinkDestinationNode(link);
  }

  graphService.closeCard = function () {
    open_card = {};
  };

  function removeIfContains(value, combined_groups) {
    var index = combined_groups.indexOf(value);
    if (index > -1) {
      combined_groups.splice(index, 1);
    }
  }

  function addToCombinedGroups(group_id) {
    // remove direct subgroups
    _.each(group_by.values, function (group) {
      if (group.parent === group_id) {
        removeIfContains(group.value, combined_groups);
      }
    });
    // add group
    combined_groups = _.union(combined_groups, [group_id]);
  }

  function removeFromCombinedGroups(group_id) {
    // remove group
    group_id = isNaN(+group_id) ? group_id : +group_id;
    removeIfContains(group_id, combined_groups);
    // add direct subgroups
    _.each(group_by.values, function (group) {
      if (group.parent === group_id) {
        combined_groups = _.union(combined_groups, [group.value]);
      }
    });
  }

  graphService.groupNode = function (node_id, node_type) {
    var node = _.find(nodes, { id: node_id, type: node_type });
    combineService.collapseBranchByGroupValue(nodes, links, graphService.network_name, group_by, node.group || node.overlay_entity_group_name);
    addToCombinedGroups(node.group || node.overlay_entity_group_name);
    all_nodes = _.cloneDeep(nodes);
  };

  graphService.selectNode = function (node_id, node_type) {
    var node = _.find(nodes, { id: node_id, type: node_type });
    node.selected = true;
  };

  function triggerFilterByCriteria() {
    if (!filtered_ids || !singles_length) { return; }
    graphService.setFilterByNodesIds(filtered_ids, singles_length);
  }

  function isHidden(node_id, node_type) {
    if (node_id === undefined || node_type === undefined) { return; }
    var node = _.find(nodes, { id: node_id, type: node_type });
    return node.hide;
  }

  graphService.inHugeGraphState = function () {
    var root_group = StateService.get(tabService.current_tab + '_selected');
    if (!root_group) { return; }
    return dataModelService.getGroupBy(root_group).employees_ids.length > 500;
  };

  //state
  function onDblClickSingleNode(node_id, node_type) {
    graphService.groupNode(node_id, node_type);
    triggerFilterByCriteria();
    graphService.setSearch(search);
  }

  function onDblClickComboNode(node_id) {
    var node = _.find(nodes, { id: node_id, type: 'combo', combo_type: 'overlay_entity' });
    if (node) {
      touched_overlay_combos.push(node_id);
    }
    node = _.find(nodes, {id: node_id});
    if (node) {
      var group_id = node.combo_group_ref.split('-')[1];
      removeFromCombinedGroups(group_id);
    }
    nodes = combineService.ungroupComboOnceById(nodes, node_id, links, graphService.network_name);
    graphService.setSearch(graphService.latest_search);
    triggerFilterByCriteria();
  }

  function onClickDefault(node_id, node_type) {
    if (isHidden(node_id, node_type) || graphService.clickOnIsolatedNode(node_id, node_type)) { return; }
    graphService.closeCard();
    // graphService.unIsolateNode();
  }

  function onDblClickDefault(node_id, node_type) {

    try {
      if (isHidden(node_id, node_type)) { return; }
      //links = _.cloneDeep(all_links);
      //nodes = _.cloneDeep(all_nodes);
      if (!node_id) { return; }
      if (node_type === 'single' || node_type === 'overlay_entity') {
        onDblClickSingleNode(node_id, node_type);
      } else {
        if (group_by.id === 1 && graphService.getNumberOfEmployeesInDirectGroup(node_id) > 500) {
          alert("Can't open group with more then 500 employees");
          return;
        }
        var group = graphService.getGroupIdFromComboId(node_id);
        if (group && group_by.id === 1 && group.employees_ids.length <= 500 && graphService.inHugeGraphState()) {
          analyzeMediator.setSelected(group.id, 'group');
        } else {
          onDblClickComboNode(node_id);
        }
      }
      graphService.highLighted(analyzeMediator.getFlagData(), analyzeMediator.id, graphService.sid);
      graphService.filterByEdgeSize(previous_limits, true);
      graphService.unIsolateNode();
    } catch (err) {
      console.error(err);
      console.trace();
    }
  }

  function onRightClickDefault(node_id, node_type, position_x, position_y) {
    if (isHidden(node_id, node_type)) { return; }
    graphService.closeCard();
    // graphService.unIsolateNode();
    if (!node_id) { return; }
    open_card.open =  true;
    open_card.node_id =  node_id;
    open_card.node_type =  node_type;
    open_card.position_x = position_x;
    open_card.position_y = position_y;
  }

  graphService.event_handlers = {
    onClick: onClickDefault,
    onDblClick: onDblClickDefault,
    onRightClick: onRightClickDefault
  };

  var default_handlers = {
    onClick: onClickDefault,
    onDblClick: onDblClickDefault,
    onRightClick: onRightClickDefault
  };

  //helpers
  graphService.neighbours = function (node_id, node_type) {
    var selected_node = _.find(nodes, { id: node_id, type: node_type });
    if (!selected_node) { return isolated_group; } //_TODO: test properly
    var neighbours = _.union(_.filter(nodes, function (node) {
      return !!_.find(links, function (link) {
        return (nodeIsOrigin(node, link) && nodeIsDestination(selected_node, link))
            || (nodeIsOrigin(selected_node, link) && nodeIsDestination(node, link));
      });
    }), [selected_node]);
    var combos = _.filter(neighbours, { type: 'combo' });
    neighbours = _.reject(neighbours, { type: 'combo' });
    _.each(combos, function (combo) {
      neighbours = _.union(neighbours, combineService.recursivelyGetSinglesInsideCombo(combo));
    });
    return neighbours;
  };

  //triggers
  graphService.setNodes = function (nodes_data, advanced) {
    if (nodes_data === undefined) {
      return;
    }
    // add verification
    nodes = _.cloneDeep(nodes_data);
    if (!advanced) {
      _.each(nodes, function (node) {
        node.type = node.node_type || 'single';
        node.hide = false;
      });
    }
  };

  graphService.setLinks = function (data) {
    // add verification
    data = _.uniq(data, function (link) {
      return JSON.stringify(_.pick(link, ['from_emp_id', 'to_emp_id', 'from_id', 'to_id', 'from_type', 'to_type']));
    });
    links = [];
    _.each(data, function (link) {
      links.push({
        from_id: link.from_emp_id || link.from_id,
        to_id: link.to_emp_id || link.to_id,
        from_type: link.from_type && link.from_type === 'from_overlay_entity' ? 'overlay_entity' : 'single',
        to_type: link.to_type && link.to_type === 'to_overlay_entity' ? 'overlay_entity' : 'single',
        way_arr: link.tow_arrow,
        weight: link.weight
      });
    });
  };

  graphService.groupOverlayEntities = function (init) {
    var overlay_entities = _.filter(nodes, function (n) { return n.type === 'overlay_entity'; });
    _.each(_.uniq(overlay_entities, function (n) { return n.overlay_entity_group_id; }), function (n) {
      if (!init || !_.contains(touched_overlay_combos, n.overlay_entity_group_name)) {
        //@@ graphService.groupNode(n.id, n.type);
      }
    });
  };

  graphService.combineNodesIfNeeded = function () {
    _.each(combined_groups, function (gr) {
      combineService.collapseBranchByGroupValue(nodes, links, graphService.network_name, group_by, gr);
    });
  };

  graphService.resetCombineService = function() {
    combineService.resetData();
  };

  graphService.setData = function (nodes, links, group_by_id, limits, group_id, layer_types, groups) {
    graphService.closeCard();
    combineService.resetData();
    graphService.measure_id = nodes.measure_id;
    graphService.network_id = links.network_index;
    graphService.group_id = group_id;
    graphService.network_name = links.name;
    graphService.layer_types = layer_types;
    graphService.setNodes(nodes.degree_list);
    graphService.setLinks(links.relation);

    if (limits) {
      graphService.filterByEdgeSize(limits, true);
    }

    //console.log(previous_limits);
    //if (previous_limits) {
    //  graphService.filterByEdgeSize(previous_limits, true);
    //}

    triggerFilterByCriteria();
    graphService.group_by_id = group_by_id;
    graphService.group_by_name = _.find(group_by_list, { id: graphService.group_by_id }).display;
    graphService.measure_name = nodes.measure_name;
    graphService.setSearch(graphService.latest_search);
    group_by = groups;
  };

  graphService.handleBidirectionalLinks = function() {
    combineService.handleBidirectionalLinks(nodes, links, group_by);
    combineService.resetData();
  };

  function normalizeLinks(links) {
    return _.map(links, function (link) {
      link.weight = 1;
      return link;
    });
  }

  graphService.setOverlayData = function (overlay_nodes, overlay_network) {
    graphService.closeCard();
    links = _.cloneDeep(all_links);
    nodes = _.cloneDeep(all_nodes);
    nodes = _.reject(nodes, function (n) {
      return (n.type === 'overlay_entity' || (n.type === 'combo' && n.combo_type === 'overlay_entity'));
    });
    if (_.isEmpty(overlay_nodes)) {
      all_nodes = _.cloneDeep(nodes);
      return;
    }
    _.each(overlay_nodes, function (n) {
      n.type = 'overlay_entity';
      n.hide = false;
      if (!n.overlay_entity_group_name) {
        n.overlay_entity_group_name = 'Ungrouped';
      }
    });
    nodes = _.union(nodes, overlay_nodes);
    links = _.reject(links, function (l) {
      return l.from_type === 'overlay_entity'
             || l.to_type === 'overlay_entity'
             || _.any(l.inner_links, function (il) { return il.from_type === 'overlay_entity' || il.to_type === 'overlay_entity'; });
    });
    overlay_network = normalizeLinks(overlay_network);
    links = links.concat(overlay_network);
    links = _.uniq(links, function (l) { return JSON.stringify(_.pick(l, ['from_id', 'from_type', 'to_id', 'to_type'])); });

    if (group_by.recursive) {
      _.each(nodes, function (n) {
        var cloned_nodes = _.cloneDeep(nodes);
        if (n.type === 'single' || n.type === 'overlay_entity') { return; }
        var group = !_.isEmpty(n.combos) ? n.combos[0].group : n.singles[0].group;
        var res = combineService.recursivelyUngroupCombo();
        var retNodes = res[0];
        cloned_nodes = _.union(cloned_nodes, retNodes);
        // The following line was remarked in the merge branch
        combineService.collapseBranchByGroupValue(cloned_nodes, links, graphService.network_name, group_by, group);
      });
    }

    if (previous_limits) {
      graphService.filterByEdgeSize(previous_limits, true);
    }
  };

  function recheckFiltered(result, nodes) {
    var hidden = _.filter(_.cloneDeep(nodes), function (n) {
      return n.hide === true;
    });
    var corrected_result = _.map(_.cloneDeep(result), function (n) {
      var found_hidden = _.find(hidden, function (hn) {
        return n.id === hn.id && n.type === hn.type;
      });
      if (found_hidden) {
        n.hide = true;
      }
      return n;
    });
    return corrected_result;
  }

  graphService.setLayout = function (layout_name, dont_reset, callback) {
    graphService.layout_name = layout_name;
    if (graphService.layout_name === 'advanced') {
      if (_.isEmpty(links)) {
        alert('The layout contains no connection data and cannot be displayed. Change the snapshot or the metric selected to view the layout.');
        return;
      }
      $timeout(function () {
        graphService.layout_in_process = true;
      }, 100, true);
      var combo_ids = _.pluck(_.filter(nodes, function (n) {
        return n.type === 'combo';
      }), 'id').sort();
      var cache_key = 'n' + graphService.network_name + 'm' + graphService.measure_name + 'g' + graphService.group_id + 's' + graphService.snapshot_id + 'gb' + group_by.id + 'grouped' + combo_ids.toString();
      var result = cached_layouts[cache_key];
      if (result) {
        result = recheckFiltered(result, nodes);
        graphService.setNodes(result, true);
        $timeout(function () {
          graphService.layout_in_process = false;
        }, 100, true);
        if (callback) {
          callback();
        }
      } else {
        rh.startFR({nodes: _.cloneDeep(nodes), links: _.cloneDeep(links)}, function (result) {
          if (!graphService.layout_in_process) { return; }
          $timeout(function () {
            graphService.layout_in_process = false;
          }, 100, true);
          graphService.setNodes(result, true);
          cached_layouts[cache_key] = result;
          if (callback) {
            $timeout(callback, 100, true);
          }
        });
      }
    } else {
      if (dont_reset) { return; }
      _.each(nodes, function (n) {
        n.x = null;
        n.y = null;
      });
    }
  };

  graphService.setGroupBy = function (data) {
    // _TODO: add verification
    if (group_by && data.id === group_by.id) { return; }
    graphService.ungroupAll(false, true);
    group_by = data;
    _.each(nodes, function (n) {
      if (!n.group) {
        n.group = 'NA';
      }
    });
  };

  graphService.setEventHandler = function (function_name, callback) {
    if (callback) {
      graphService.event_handlers[function_name] = callback;
    } else {
      graphService.event_handlers[function_name] = default_handlers[function_name];
    }
  };

  function highestNodes(parent) {
    var root_values = _.pluck(_.where(group_by.values, { parent: parent }), 'value');
    var root_nodes = _.filter(nodes, function (node) {
      return _.contains(root_values, node.group);
    });
    if (_.isEmpty(root_nodes)) {
      root_nodes = _.reduce(root_values, function (start, value) {
        return _.union(start, highestNodes(value));
      }, []);
    }
    return root_nodes;
  }

  function capitalize(str) {
    if (typeof str !== 'string') { return; }
    return _(str.split(' ')).map(function (w) { return w.charAt(0).toUpperCase() + w.slice(1); }).value().join(' ');
  }

  graphService.groupAll = function () {
    StateService.set({ name: 'network_graph', value: {
      selected_group_ungroup_all: 'group_all' }
    });
    graphService.closeCard();
    graphService.ungroupAll(true);
    if (!group_by.recursive) {
      _.each(group_by.values, function (value) {
        addToCombinedGroups(value.value);
      });
      combineService.collapseAllBranchsByGroupValue(nodes, links, graphService.network_name, group_by);
    } else {
      var highest_group_values = _.where(group_by.values, { parent: null });
      _.each(highest_group_values, function (group) {
        addToCombinedGroups(group.value);
        combineService.collapseAllByGroupValue(nodes, links, graphService.network_name, group_by, group.value);
      });
    }
    _.each(_.filter(nodes, { combo_type: 'overlay_entity' }), function (n) {
      addToCombinedGroups(n.name);
    });
    triggerFilterByCriteria();
    graphService.filterByEdgeSize(previous_limits, true);
    graphService.setSearch(search);
    graphService.unIsolateNode();
  };

  graphService.ungroupAll = function (from_group_all, from_set_group_by) {
    StateService.set({ name: 'network_graph', value: {
      selected_group_ungroup_all: 'ungroup_all' }
    });
    links = _.cloneDeep(all_links);
    nodes = _.cloneDeep(all_nodes);
    graphService.closeCard();

    var combos = _.filter(nodes, { type: 'combo' });
    if (combos.length > 0) {
      var ret = combineService.recursivelyUngroupCombo();
      nodes = ret[0];
      links = ret[1];
    }
    if (!from_group_all) {
      combined_groups.splice(0, combined_groups.length);
    }
    graphService.groupOverlayEntities(true);
    if (!from_group_all) {
      graphService.filterByEdgeSize(previous_limits, true);
      if (!from_set_group_by) {
        graphService.unIsolateNode();
      }
    }
    triggerFilterByCriteria();
    graphService.highLighted(analyzeMediator.getFlagData(), analyzeMediator.id, graphService.sid);
    graphService.setSearch(graphService.latest_search);
  };

  graphService.setSearch = function (node) {
    search = {};
    if (!node) { return; }
    if (combineService.isNodeOpen(nodes, node)) {
      search.id = node.id;
      search.type = node.type;
    } else {
      graphService.setSearch(combineService.comboContainingNode(nodes, node));
    }
  };

  function coloredLinks(links, isolated_node, color) {
    var cloned_links = _.cloneDeep(links);
    _.each(cloned_links, function (link) {
      if (nodeIsOrigin(isolated_node, link) || nodeIsDestination(isolated_node, link)) {
        link.color = color;
      }
    });
    return cloned_links;
  }

  function mapIdAndType(nodes) {
    return _.map(nodes, function (node) {
      return { id: node.id, type: node.type };
    });
  }

  function intersectObjects(arr1, arr2) {
    return _.filter(arr1, function (e1) {
      return !!_.find(arr2, function (e2) {
        return _.eq(e1, e2);
      });
    });
  }

  graphService.clickOnIsolatedNode = function (node_id, node_type) {
    var isoloated = graphService.getIsolated();
    if (_.isEmpty(isoloated)) { return; }
    return (isoloated.id === node_id && isoloated.type === node_type);
  };

  function removeIsolatedFilter(array) {
    _.each(array, function (node) {
      if (node.type === 'single') {
        analyzeMediator.filter.remove('id', node.id);
      } else {
        analyzeMediator.filter.remove('external_id', node.id);
      }
    });
    graphService.setFilter(analyzeMediator.filter.getFiltered(), analyzeMediator.filter.getFilterGroupIds());
  }

  graphService.unIsolateNode = function () {
    if (isolated) {
      links = coloredLinks(links, isolated, link_color);
      removeIsolatedFilter(isolated_group);
      isolated_group = [];
      isolated = {};
    }
  };

  graphService.allSingles = function (arr) {
    return _.union(_.reduce(arr, function (init, n) {
      return _.union(init, n.type === 'single' || n.type === 'overlay_entity' ? [n] : combineService.recursivelyGetSinglesInsideCombo(n));
    }, []));
  };

  function addIsolatedFilter(array) {

    _.each(array, function (node) {
      if (node.type === 'single') {
        analyzeMediator.filter.add('id', node.id);
      } else {
        analyzeMediator.filter.add('external_id', node.id);
      }
    });

    graphService.setFilter(analyzeMediator.filter.getFiltered(), analyzeMediator.filter.getFilterGroupIds());
  }

  graphService.setIsolated = function (node_id, node_type) {
    if (!node_id || !node_type) {
      return;
    }
    var neighbours = graphService.neighbours(node_id, node_type);

    if (intersectObjects(mapIdAndType(isolated_group), mapIdAndType(neighbours)).length !== mapIdAndType(neighbours).length) {
      isolated_group = neighbours;  //graphService.allSingles(neighbours);
      addIsolatedFilter(isolated_group);
    }

    isolated = { id: node_id, type: node_type };
    links = coloredLinks(links, isolated, 'grey');
  };

  function isComboShown(combo, single_ids) {
    var singles = combineService.recursivelyGetSinglesInsideCombo(combo);
    var shown = false;
    _.each(singles, function (single) {
      if (_.contains(single_ids, single.id)) {
        shown = true;
        return false;
      }
    });
    return shown;
  }

  function isNodeShown(node, single_ids) {
    return node.type === 'single' || node.type === 'overlay_entity' ? _.contains(single_ids, node.id) : isComboShown(node, single_ids);
  }

  function isNodeHidden(node, ids) {
    var type;
    if (node.type === 'overlay_entity' || (node.type === 'combo' && node.combo_type === 'overlay_entity')) {
      type = 'overlay';
    } else {
      type = 'employee';
    }
    return !isNodeShown(node, ids[type]);
  }

  function isSingleToSingle(link) {
    var single_types = ['single', 'overlay_entity'];
    return _.include(single_types, link.from_type) && _.include(single_types, link.to_type);
  }

  function toShownSingle(link, ids) {
    if (link.to_type === 'combo') {
      console.log('error in filter links by ids');
    }
    var type = link.to_type === 'single' ? 'employee' : 'overlay';
    return _.contains(ids[type], link.to_id);
  }

  function fromShownSingle(link, ids) {
    if (link.from_type === 'combo') {
      console.log('error in filter links by ids');
    }
    var type = link.from_type === 'single' ? 'employee' : 'overlay';
    return _.contains(ids[type], link.from_id);
  }

  function isOneEndHidden(link, filtered_ids) {
    var from_node = linkOriginNode(link);
    var to_node = linkDestinationNode(link);
    if (isSingleToSingle(link)) {
      return !(fromShownSingle(link, filtered_ids) && toShownSingle(link, filtered_ids));
    }
    if (from_node && to_node) { return false; }
    return from_node.hide || to_node.hide || isNodeHidden(from_node, filtered_ids) || isNodeHidden(to_node, filtered_ids);
  }

  function getOriginalLinks(link) {
    return link.inner_links;
  }

  graphService.setFilterByNodesIds = function (ids, number_of_singles) {
    filtered_ids = ids;
    // ids = ids.employee;
    singles_length = number_of_singles;
    if (ids.employee.length + ids.overlay.length === number_of_singles) {
      _.each(_.union(nodes, links), function (item) {
        item.hide = false;
      });
      graphService.number_of_nodes = ids.employee.length;
      return;
    }
    //filter single nodes
    _.each(nodes, function (node) {
      node.hide = isNodeHidden(node, ids);
    });
    //links
    var visible_links = graphService.getLinks();
    _.each(visible_links, function (link) {
      if (isSingleToSingle(link)) {
        link.hide = !(fromShownSingle(link, ids) && toShownSingle(link, ids));
      } else {
        link.hide = isOneEndHidden(link, ids) || _.inject(getOriginalLinks(link), function (prev_hidden, original_link) {
          return prev_hidden && isOneEndHidden(original_link, ids);
        }, true);
      }
    });
    graphService.number_of_nodes = ids.employee.length;
  };

  graphService.filterByEdgeSize = function (limits, save_data) {
    previous_limits = limits;

    if (save_data) {
      all_links = _.cloneDeep(links);
      all_nodes = _.cloneDeep(nodes);
    }
    links = _.filter(all_links, function (link) {
      var linkInRange   = _.inRange(link.weight, limits.from, limits.to);
      var linkEqTo      = link.weight === limits.to;
      var isOverlayLink = link.to_type === 'overlay_entity' || link.from_type === 'overlay_entity';
      return (linkInRange || linkEqTo || isOverlayLink);
    });
    links = _.filter(links, function (link) {
      return (_.contains(_.pluck(nodes, 'id'), link.from_id) && _.contains(_.pluck(nodes, 'id'), link.to_id));
    });
    triggerFilterByCriteria();
  };

  //callbacks

  graphService.getNodes = function () {
    return nodes;
  };

  graphService.getLinks = function () {
    var ls =  _.filter(links, function (link) {
      var from_match = _.any(nodes, _.matches({
        id: link.from_id,
        type: link.from_type
      }));

      var to_match = _.any(nodes, _.matches({
        id: link.to_id,
        type: link.to_type
      }));

      return to_match && from_match && !link.remove;
    });
    return ls;
  };

  graphService.getLayout = function () {
    if (!nodes || !links) { return; }
    return { layout: graphService.layout_name };
  };

  graphService.getSearch = function () {
    return search;
  };

  graphService.getIsolated = function () {
    return isolated;
  };

  graphService.getIsolatedGroup = function () {
    return isolated_group;
  };

  graphService.getEverythingInsideAllCombos = function () {
    var combos = _.where(nodes, { type: 'combo' });
    var res = _.reduce(combos, function (total_singles, combo) {
      return _.union(total_singles, combineService.recursivelyGetEverythingInsideCombo(combo));
    }, []);
    return res;
  };

  graphService.getEventHandlerOnClick = function (node_id, node_type, position_x, position_y) {
    return graphService.event_handlers.onClick(node_id, node_type, position_x, position_y);
  };

  graphService.getEventHandlerOnDblClick = function (node_id, node_type, position_x, position_y) {
    return graphService.event_handlers.onDblClick(node_id, node_type, position_x, position_y);
  };

  graphService.getEventHandlerOnRightClick = function (node_id, node_type, position_x, position_y) { //open card
    return graphService.event_handlers.onRightClick(node_id, node_type, position_x, position_y);
  };

  graphService.getEmployeeDetails = function (id) {
    var node = _.find(nodes, { id: id, type: 'single' });
    if (!node) { return; }
    var employee_view = {};
    var emp_details = dataModelService.getEmployeeById(id);
    employee_view.name = emp_details.first_name + " " + emp_details.last_name;
    employee_view.email = emp_details.email;
    employee_view.rate = Math.round(node.rate * 100) / 1000;
    employee_view.age = emp_details.age || 'N/A';
    employee_view.seniority = emp_details.seniority || 'N/A';
    employee_view.rank = emp_details.rank || 'N/A';
    employee_view.role_type = emp_details.role_type || 'N/A';
    employee_view.img_url = emp_details.img_url;
    employee_view.g_name = dataModelService.getGroupBy(emp_details.group_id).name || 'N/A';
    employee_view.division_name = dataModelService.getDivisionName(emp_details.group_id);
    employee_view.office = emp_details.office || 'N/A';
    employee_view.job_title = emp_details.job_title || 'N/A';
    employee_view.isolated = graphService.getIsolated() && graphService.getIsolated().type === 'single' && graphService.getIsolated().id === id;
    return employee_view;
  };

  graphService.getGroupDetails = function (id) {
    var group_view = {};
    var group_details = _.find(nodes, {id: id, type: 'combo'});

    // var rate = self.calcGroupWidth(group_details.d.employee_list) * 0.1;
    group_view.standard_deviation = combineService.calculateComboStandardDeviation( group_details );
    group_view.name = group_details.name;
    group_view.top_group = group_details.group === undefined || group_details.group === null;
    group_view.rate = combineService.calculateComboRate( group_details );
    group_view.combo_type = group_details.combo_type;
    group_view.overlay_entity_type = group_details.overlay_entity_type;
    group_view.isolated = graphService.getIsolated() && graphService.getIsolated().type === 'combo' && graphService.getIsolated().id === id;
    return group_view;
  };

  graphService.getOverlayEntityDetails = function (id) {
    var view = _.find(nodes, { id: id, type: 'overlay_entity' }); // TODO: need to bring group (domain) separately
    view.isolated = graphService.getIsolated() && graphService.getIsolated().type === 'overlay_entity' && graphService.getIsolated().id === id;
    return view;
  };

  graphService.highLighted = function (flag_data, group_id, sid) {
    if (!flag_data || !sid) {
      graphService.clearHighligthed();
      return;
    }
    graphService.clearHighligthed();
    if (flag_data.algorithm_type !== FLAG) { return; }
    dataModelService.getFlaggedEmployees(flag_data.company_metric_id, group_id, sid, true).then(function (flagged_employees) {
      var highlighted_nodes = _.filter(nodes, function (node) { return _.include(flagged_employees, node.id) && node.type === 'single'; });
      _.each(highlighted_nodes, function (node) { node.highlighted = '#7C60A9'; });
    });
  };

  graphService.clearHighligthed = function () {
    _.each(nodes, function (node) { if (node.type === 'single') { node.highlighted = null; } });
  };

  function sortRelation(relations_list) {
    relations_list = _.each(relations_list, function (relations) { relations = _.sortByAll(relations, ['from_emp_id', 'to_emp_id']); });
    return relations_list;
  }

  graphService.createRelationsFromMoreThenOneNetworks = function (networks) {
    var largest_network = networks[0];
    var new_relation;
    _.each(networks, function (network) {
      if (largest_network.length < network.length) { largest_network = network; }
    });
    new_relation = _.cloneDeep(largest_network);
    _.each(networks, function (network) {
      if (!_.isEqual(new_relation, network)) {
        _.each(network, function (rel) {
          if (!_.find(new_relation, { to_emp_id: rel.to_emp_id, from_emp_id: rel.from_emp_id })) {
            new_relation.push(rel);
          }
        });
      }
    });
    return new_relation;
  };

  function convertEmailRelationToBinari(relations) {
    var binari_relation = [];
    _.each(relations, function (rel) {
      if (rel.weight >= 3) {
        rel.weight = 1;
        binari_relation.push(rel);
      }
    });
    return binari_relation;
  }
  graphService.createNewNetwork = function (networks, bundle_ids) {
    var new_network = { network_bundle: bundle_ids};
    new_network.network_index = bundle_ids.toString();
    var relation_list = _.pluck(_.reject(networks, function (network) { return network.name === 'Communication Flow'; }), 'original_relation');
    var email_network = _.find(networks, { name: 'Communication Flow'});
    if (email_network) {
      var binari_relation = convertEmailRelationToBinari(_.cloneDeep(email_network.original_relation));
      relation_list.push(binari_relation);
    }
    var relation_arr = graphService.createRelationsFromMoreThenOneNetworks(sortRelation(relation_list));
    new_network.original_relation = _.cloneDeep(relation_arr);
    new_network.relation = relation_arr;
    return new_network;
  };

  graphService.getGroupIdFromComboId = function (combo_id) {
    var node_to_collapse = _.find(graphService.getNodes(), { 'id': combo_id});
    return dataModelService.getGroupBy(node_to_collapse.id);
  };

  graphService.getNumberOfEmployeesInDirectGroup = function (combo_id) {
    var group = graphService.getGroupIdFromComboId(combo_id);
    return group ? dataModelService.getEmployeesByGroupId(group.id).length : 0;
  };

  // MOCKS ================================================================================

  graphService.mock = function () {
    function createNodesMock() {
      nodes = [{
        id: 5,
        rate: 40,
        type: 'single'
      }, {
        id: 3,
        rate: 70,
        type: 'single'
      }, {
        id: 'male',
        rate: 80,
        type: 'combo'
      }];
    }

    function createLinksMock() {
      links = [{
        from_id: 'male',
        from_singles: [8],
        from_type: 'combo',
        to_id: 5,
        to_type: 'single',
        weight: 2
      }, {
        from_id: 'male',
        from_singles: [15],
        from_type: 'combo',
        to_id: 5,
        to_type: 'single',
        weight: 6
      }];
    }
    createNodesMock();
    createLinksMock();
  };

  graphService.getLinksForTest = function () {
    return links;
  };

  graphService.mockToFilterComboAndSingles = function () {
    nodes = [];
    links = [];
    group_by = { recursive: false };
    // group_by.values = [{ parent: null, value: 'combo1'}, { parent: 1, value: 'combo2'}];
    previous_limits = { from: 1, to: 6 };
    nodes.push(createNewNode(1, 'single', 10, 'combo1'));
    nodes.push(createNewNode(2, 'single', 20, 'combo2'));
    nodes.push(createNewNode(3, 'single', 30, 'combo2'));
    nodes.push(createNewNode(4, 'single', 40, 'combo3'));
    nodes.push(createNewNode(5, 'single', 40, 'combo1'));
    links.push(createNewLink(3, 'single', 1, 'single', 1));
    links.push(createNewLink(1, 'single', 2, 'single', 1));
    links.push(createNewLink(4, 'single', 2, 'single', 1));
    links.push(createNewLink(4, 'single', 3, 'single', 1));
    links.push(createNewLink(5, 'single', 3, 'single', 1));
    links.push(createNewLink(5, 'single', 2, 'single', 1));
  };

  graphService.mockSingleAndCombos = function () {
    group_by = { recursive: true, id: 1 };
    group_by.values = [
      {
        parent: null,
        value: 1
      },
      {
        parent: 1,
        value: 2
      },
      {
        parent: 2,
        value: 3
      },
      {
        parent: null,
        value: 4
      }
    ];

    function createNodesMock() {
      nodes =
        [
          {
            id: 1,
            type: 'single',
            group: 1
          },
          {
            id: 2,
            type: 'combo',
            group: 2,
            combos: [{
              id: 3,
              group: 2,
              type: 'single'
            }]
          },
          {
            id: 4,
            group: 4,
            type: 'single'
          },
          {
            id: 5,
            group: 4,
            type: 'single'
          }
        ];
    }

    function createLinksMock() {
      links = [
        {
          from_type: 'single',
          to_type: 'combo',
          from_id: 1,
          to_id: 2,
          weight: 3
        },
        {
          from_type: 'single',
          to_type: 'single',
          from_id: 1,
          to_id: 4,
          weight: 2
        },
        {
          from_type: 'single',
          to_type: 'single',
          from_id: 4,
          to_id: 1,
          weight: 1
        },
        {
          from_type: 'single',
          to_type: 'single',
          from_id: 3,
          to_id: 4,
          weight: 4
        }
      ];
    }
    createNodesMock();
    createLinksMock();
  };

  graphService.mockSingleAndCombosMore = function () {
    previous_limits = { from: 1, to: 6 };
    group_by = { recursive: true };
    group_by.values = [
      {
        parent: null,
        value: 1
      },
      {
        parent: 1,
        value: 2
      },
      {
        parent: 2,
        value: 3
      },
      {
        parent: 2,
        value: 4
      }
    ];

    nodes = [
      {
        id: 1,
        type: 'single',
        group: 1
      },
      {
        id: 2,
        type: 'single',
        group: 2
      },
      {
        id: 4,
        type: 'combo',
        group: 2,
        singles: [
          {
            id: 3,
            group: 3,
            type: 'single'
          }
        ]
      },
      {
        id: 5,
        type: 'combo',
        group: 2,
        singles: [
          {
            id: 6,
            type: 'single',
            group: 4
          }
        ]
      }
    ];
    links = [
      {
        from_type: 'single',
        to_type: 'combo',
        from_id: 1,
        to_id: 5,
        weight: 3
      },
      {
        from_type: 'combo',
        to_type: 'single',
        from_id: 5,
        weight: 4,
        to_id: 1
      },
      {
        from_type: 'single',
        to_type: 'single',
        from_id: 6,
        to_id: 1,
        weight: 3,
        way_arr: true
      },
      {
        from_type: 'single',
        to_type: 'combo',
        from_id: 1,
        weight: 2,
        to_id: 4
      },
      {
        from_type: 'single',
        to_type: 'single',
        from_id: 1,
        to_id: 3,
        way_arr: false
      },
      {
        from_type: 'single',
        to_type: 'combo',
        from_id: 2,
        to_id: 4,
        weight: 5
      },
      {
        from_type: 'combo',
        to_type: 'single',
        from_id: 4,
        to_id: 2,
        weight: 6
      },
      {
        from_type: 'single',
        to_type: 'single',
        from_id: 3,
        to_id: 2,
        weight: 1,
        way_arr: true
      }
    ];
  };

  graphService.mockCombinedNodes = function () {
    previous_limits = { from: 1, to: 6 };
    nodes = [{ id: 1, type: 'combo', singles: [
              { id: 1, type: 'single'},
              { id: 2, type: 'single' }], combos: [
            { id: 2, type: 'combo', singles: [
              { id: 3, type: 'single' },
              { id: 4, type: 'single' }] },
            { id: 3, type: 'combo', singles: [
              { id: 5, type: 'single' }]
            }]},
      { id: 4, type: 'combo', singles: [
        { id: 6, type: 'single' }] },
      { id: 7, type: 'single' }];
  };

  graphService.mockNoSinglesOneLevel = function () {
    nodes = [
      { id: 1, type: 'combo', singles: [
        { id: 1, type: 'single'},
        { id: 2, type: 'single' }] },
      { id: 2, type: 'combo', singles: [
        { id: 3, type: 'single' },
        { id: 4, type: 'single' }] },
      { id: 3, type: 'combo', singles: [
        { id: 5, type: 'single' }] },
      { id: 4, type: 'combo', singles: [
        { id: 6, type: 'single' }] }
    ];
    var single_links = [
      { from_id: 1, from_type: 'single', to_id: 3, to_type: 'single' },
      { from_id: 2, from_type: 'single', to_id: 4, to_type: 'single' },
      { from_id: 3, from_type: 'single', to_id: 5, to_type: 'single' },
      { from_id: 5, from_type: 'single', to_id: 6, to_type: 'single' },
      { from_id: 3, from_type: 'single', to_id: 6, to_type: 'single' },
      { from_id: 4, from_type: 'single', to_id: 6, to_type: 'single' }
    ];
    links = _.union([
      { from_id: 1, from_type: 'combo', to_id: 2, to_type: 'combo', inner_links: [single_links[0], single_links[1]] },
      { from_id: 2, from_type: 'combo', to_id: 3, to_type: 'combo', inner_links: [single_links[2]] },
      { from_id: 3, from_type: 'combo', to_id: 4, to_type: 'combo', inner_links: [single_links[3]] },
      { from_id: 2, from_type: 'combo', to_id: 4, to_type: 'combo', inner_links: [single_links[4], single_links[5]] }
    ], single_links);
  };

  graphService.mockNoSinglesMultipleLevel = function () {
    nodes = [
      { id: 1, type: 'combo', singles: [
        { id: 3, type: 'single'}], combos: [
        { id: 2, type: 'combo', singles: [
          { id: 1, type: 'single' },
          { id: 2, type: 'single' }] }] },
      { id: 3, type: 'combo', combos: [
        { id: 4, type: 'combo', combos: [
          { id: 5, type: 'combo', singles: [
            { id: 4, type: 'single' },
            { id: 5, type: 'single' }] }] }] },
      { id: 6, type: 'combo', combos: [
        { id: 7, type: 'combo', singles: [
          { id: 7, type: 'single' }], combos: [
          { id: 8, type: 'combo', singles: [
            { id: 6, type: 'single' }] }] },
        { id: 9, type: 'combo', singles: [
          { id: 8, type: 'single' },
          { id: 9, type: 'single' }] }] },
      { id: 10, type: 'combo', singles: [
        { id: 10, type: 'single' }] }
    ];
    var single_links = [
    //original singles
      { from_id: 1, from_type: 'single', to_id: 4, to_type: 'single' },
      { from_id: 2, from_type: 'single', to_id: 5, to_type: 'single' },
      { from_id: 4, from_type: 'single', to_id: 8, to_type: 'single' },
      { from_id: 9, from_type: 'single', to_id: 10, to_type: 'single' },
      { from_id: 5, from_type: 'single', to_id: 10, to_type: 'single' }
    ];
    links = _.union([
    // visible
      { from_id: 1, from_type: 'combo', to_id: 3, to_type: 'combo', inner_links: [single_links[0], single_links[1]] },
      { from_id: 3, from_type: 'combo', to_id: 6, to_type: 'combo', inner_links: [single_links[2]] },
      { from_id: 6, from_type: 'combo', to_id: 10, to_type: 'combo', inner_links: [single_links[3]] },
      { from_id: 3, from_type: 'combo', to_id: 10, to_type: 'combo', inner_links: [single_links[4]] },
    //combinations byproducts
      { from_id: 1, from_type: 'single', to_id: 5, to_type: 'combo', inner_links: [single_links[0]] },
      { from_id: 1, from_type: 'single', to_id: 4, to_type: 'combo', inner_links: [single_links[0]] },
      { from_id: 1, from_type: 'single', to_id: 3, to_type: 'combo', inner_links: [single_links[0]] },
      { from_id: 2, from_type: 'combo', to_id: 4, to_type: 'single', inner_links: [single_links[0]] },
      { from_id: 1, from_type: 'combo', to_id: 4, to_type: 'single', inner_links: [single_links[0]] },
      { from_id: 2, from_type: 'single', to_id: 5, to_type: 'combo', inner_links: [single_links[1]] },
      { from_id: 2, from_type: 'single', to_id: 4, to_type: 'combo', inner_links: [single_links[1]] },
      { from_id: 2, from_type: 'single', to_id: 3, to_type: 'combo', inner_links: [single_links[1]] },
      { from_id: 2, from_type: 'combo', to_id: 5, to_type: 'single', inner_links: [single_links[1]] },
      { from_id: 1, from_type: 'combo', to_id: 5, to_type: 'single', inner_links: [single_links[1]] },
      { from_id: 2, from_type: 'combo', to_id: 5, to_type: 'combo', inner_links: [single_links[0], single_links[1]] },
      { from_id: 2, from_type: 'combo', to_id: 4, to_type: 'combo', inner_links: [single_links[0], single_links[1]] },
      { from_id: 2, from_type: 'combo', to_id: 3, to_type: 'combo', inner_links: [single_links[0], single_links[1]] },
      { from_id: 1, from_type: 'combo', to_id: 5, to_type: 'combo', inner_links: [single_links[0], single_links[1]] },
      { from_id: 1, from_type: 'combo', to_id: 4, to_type: 'combo', inner_links: [single_links[0], single_links[1]] },
      { from_id: 5, from_type: 'single', to_id: 10, to_type: 'combo', inner_links: [single_links[4]] },
      { from_id: 5, from_type: 'combo', to_id: 10, to_type: 'combo', inner_links: [single_links[4]] },
      { from_id: 4, from_type: 'combo', to_id: 10, to_type: 'combo', inner_links: [single_links[4]] },
      { from_id: 5, from_type: 'combo', to_id: 10, to_type: 'single', inner_links: [single_links[4]] },
      { from_id: 4, from_type: 'combo', to_id: 10, to_type: 'single', inner_links: [single_links[4]] },
      { from_id: 3, from_type: 'combo', to_id: 10, to_type: 'single', inner_links: [single_links[4]] }
    ], single_links);
  };

  graphService.mockNoCombos = function () {
    previous_limits = { from: 1, to: 6 };
    nodes = [{ id: 1, type: 'single' },
             { id: 2, type: 'single' },
             { id: 3, type: 'single' },
             { id: 4, type: 'single' }];
    links = [{ from_id: 1, from_type: 'single', to_id: 2, to_type: 'single' },
             { from_id: 2, from_type: 'single', to_id: 3, to_type: 'single' },
             { from_id: 3, from_type: 'single', to_id: 4, to_type: 'single' },
             { from_id: 4, from_type: 'single', to_id: 1, to_type: 'single' }];
  };

  graphService.mockGroupByStructure = function () {
    previous_limits = { from: 1, to: 6 };
    nodes = [{
      id: 1,
      type: 'single',
      group: 1
    }, {
      id: 2,
      type: 'single',
      group: 2
    }, {
      id: 3,
      type: 'single',
      group: 3
    }, {
      id: 4,
      type: 'single',
      group: 4
    }];
    group_by = {
      id: 4,
      display: 'Structure',
      name: 'group_id',
      recursive: true,
      values: [{ value: 1, parent: null, name: 1 }, { value: 2, parent: 1, name: 2 }, { value: 3, parent: 2, name: 3 }, { value: 4, parent: 2, name: 4 }]
    };
  };

  graphService.mockSingleAndComboToCalculateEdgeWeight = function () {
    nodes = [];
    links = [];
    previous_limits = { from: 1, to: 6 };
    group_by = { recursive: false };
    nodes.push(createNewNode(48, 'single', 50, 'combo1'));
    nodes.push(createNewNode(49, 'single', 80, 'combo1'));
    nodes.push(createNewNode(47, 'single', 70, 'combo2'));
    links.push(createNewLink(48, 'single', 47, 'single', 1));
    var link_with_two_direction = createNewLink(49, 'single', 47, 'single', 1);
    link_with_two_direction.way_arr = true;
    links.push(link_with_two_direction);
  };

  graphService.mockNodesWithNoAttribute = function () {
    previous_limits = { from: 1, to: 6 };
    nodes = [{
      id: 1,
      type: 'single'
    }, {
      id: 2,
      type: 'single'
    }];
    links = [];
    group_by = {
      id: 1,
      name: 'some_missing_attribute',
      values: [1, 2, 4, 0]
    };
  };

  graphService.mockLinksWithWeights = function () {
    links = [];
    nodes = [];
    _.each([1, 2, 3, 4, 5, 6, 7], function (id) {
      nodes.push(createNewNode(id, 'single', 1));
    });
    _.each([1, 2, 3, 4, 5, 6], function (weight) {
      links.push(createNewLink(weight, 'single', weight + 1, 'single', weight));
    });
  };

  graphService.mockSinglesCombosAndLinks = function () {
    nodes = [{ id: 1, type: 'single' },
             { id: 2, type: 'single' },
             { id: 4, type: 'combo', singles: [{ id: 3, type: 'single' },
                                               { id: 7, type: 'single' }]
             },
             { id: 5, type: 'combo', singles: [{ id: 6, type: 'single' }],
                                     combos: [{ id: 8, type: 'combo',
                                       singles: [{ id: 9, type: 'single' }] }] },
             { id: 10, type: 'combo', singles: [{ id: 11, type: 'single' }] }
            ];
    var single_links = [{ from_id: 1, from_type: 'single', to_id: 7, to_type: 'single' },
                        { from_id: 2, from_type: 'single', to_id: 7, to_type: 'single' },
                        { from_id: 1, from_type: 'single', to_id: 9, to_type: 'single' },
                        { from_id: 1, from_type: 'single', to_id: 11, to_type: 'single' }];
    links = _.union([{ from_id: 1, from_type: 'single', to_id: 4, to_type: 'combo', inner_links: [single_links[0]] },
             { from_id: 2, from_type: 'single', to_id: 4, to_type: 'combo', inner_links: [single_links[1]] },
             { from_id: 1, from_type: 'single', to_id: 5, to_type: 'combo', inner_links: [single_links[2]] },
             { from_id: 1, from_type: 'single', to_id: 10, to_type: 'combo', inner_links: [single_links[3]] }],
             single_links);
  };

  graphService.mockHalfCombinedWithIsolated = function () {
    nodes = [{ id: 1, type: 'single', group: 'female' },
             { id: 2, type: 'single', group: 'female' },
             { id: 'male', type: 'combo', singles: [
                { id: 3, type: 'single', group: 'male' },
                { id: 4, type: 'single', group: 'male' }] }];
    all_nodes = nodes;
    group_by = {
      id: 1,
      display: 'Gender',
      name: 'gender',
      values: ['male', 'female']
    };
    isolated = { id: 'male', type: 'combo' };
  };

  graphService.mockAllNodesAndLinks = function () {
    all_nodes = _.cloneDeep(nodes);
    all_links = _.cloneDeep(links);
  };
  graphService.getAllLinks = function () {
    return all_links;
  };
  graphService.getAllNodes = function () {
    return all_nodes;
  };
  graphService.getCachedLayouts = function () {
    return _.cloneDeep(cached_layouts);
  };
  graphService.getLinksNotFiltered = function () {
    return links;
  };

  return graphService;
});

