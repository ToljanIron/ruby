/*globals angular, _*/

angular.module('workships.services').factory('combineService', function () {
  'use strict';

  /******************************************************************************************
   * The code is generally partitioned into the following sections:
   *
   * - Utilities
   * - Hash and Key functions
   * - Prepare indexes
   * - Creators
   * - Core combine
   * - APIs
   *
   * This section describes the basic service's logic:
   * ---------------------------------------------------------
   * To optimize access to the various entities (nodes, links, groups) all input arrays are
   * indexed into hash_tables, and all cross references among object are hash-keys. The stage
   * creating the indexes is calle: "Prepare" and it happens proir to any actuall calculations.
   *
   * - Node keys start with 'N', ie the key to a node whose ID is 17 is 'N-17'
   * - Group keys start with 'G', ie a group whose ID is 7 is 'G-7', and a group whose name is 'male'
   *   is: 'G-male'
   * - Cobmo keys start also with 'N' but they will have the number: 100000 appended to them, so
   *   group's 17 combo's key is: 'N-100017', and group's 'Netanya's combo key is:
   *   'N-100000Netanya'
   * - Link keys begin with 'L', followed by from node's ID and then to node's ID. For example:
   *   'L-18-100003' is a link from node 17 to combo of group 3
   *
   * In order to avoid maintaining complicated states, every change in network presentation
   * rebuilds entire network sections from the ground up. The only state that's maintained is
   * which combos exist.
   * Because a combo represents both a group as well as a node in Keylines, it doesn't necesssarily
   * have a clear place. Since keylines will need them in the nodes array then that is where they
   * are maintained (as well as in nodes_hash).
   * Every time a combo is created or destroyed all links, node rates and link weights related to
   * it are recalculated. The sections below describe this:
   *
   * - combine a group:
   *   - A combo is created
   *   - All nodes (and combos) under it are hidden
   *   - All links related to nodes anywhere under the group (including under sub-groups) change
   *     references. Example: If we combine G-3 having node N-17 under it with link L-17-25
   *     which points to a node not under G-3, then a new link is created: L-100017-25.
   *   - Link weights are recalculated
   *
   * - uncombine:
   *   - The combo is removed
   *   - repeat procedure above for links
   *   - perform combine for every group under the group which is uncombined
   *   - Recalculate link weights
   *
  ******************************************************************************************/

  var combineService = {};
  /**
   * priv is a way to expose private functions for test purposes without polluting the
   * entire name space
   */
  var priv = {};
  combineService.priv = priv;

  var DEBUG           = false;
  var COMBO_IDS_RANGE = 100000;
  var EMAILS          = 'Communication Flow';
  var COMBO           = 'combo';
  var OVERLAY_ENTITY  = 'overlay_entity';

//======== Indexes  =============
  var links_hash    = {};
  var nodes_hash    = {};
  var groups_hash   = {};
  combineService.priv.links_hash = links_hash;
//======== Indexes  =============

// ===================== Utilities ==================================================== //
  function everlog(m1,m2,m3,m4,m5,m6,m7,m8,m9,m10) {
    if (m1 === undefined) { return; }
    if (m2 === undefined) { return console.log(m1); }
    if (m3 === undefined) { return console.log(m1, m2); }
    if (m4 === undefined) { return console.log(m1, m2, m3); }
    if (m5 === undefined) { return console.log(m1, m2, m3, m4); }
    if (m6 === undefined) { return console.log(m1, m2, m3, m4, m5); }
    if (m7 === undefined) { return console.log(m1, m2, m3, m4, m5, m6); }
    if (m8 === undefined) { return console.log(m1, m2, m3, m4, m5, m6, m7); }
    if (m9 === undefined) { return console.log(m1, m2, m3, m4, m5, m6, m7, m8); }
    if (m10 === undefined){ return console.log(m1, m2, m3, m4, m5, m6, m7, m8, m9); }
    return console.log(m1, m2, m3, m4, m5, m6, m7, m8, m9, m10);
  }

  function logger(m1,m2,m3,m4,m5,m6,m7,m8,m9,m10) {
    if (DEBUG === false) { return; }
    everlog(m1,m2,m3,m4,m5,m6,m7,m8,m9,m10);
  }

  function pp(arr) {
    everlog('--------------------');
    _.forEach(arr, function(e) {
      everlog(e);
    });
    everlog('--------------------');
  }
  angular.noop(pp);

// ================== End Utilities ==================================================== //

// ================== Hash Function ==================================================== //

  // --------------- Groups -------------------------------
  var groupKeyFromId = function(group_id) {
    return ['G', group_id].join('-');
  };

  var groupKey = function(group) {
    if (group === undefined || group === null) { return undefined; }
    return groupKeyFromId( group.value );
  };

  var getGroup = function(group_key) {
    if (_.isNumber(group_key)) {
      group_key = group_key.toString();
    }
    if (group_key.charAt(0) !== 'G') {
      group_key = groupKeyFromId(group_key);
    }
    return groups_hash[group_key];
  };

  // --------------- Nodes -------------------------------
  var nodeKey = function(node) {
    return ['N', node.id].join('-');
  };

  var nodeKeyFromId = function(node_id) {
    return ['N', node_id].join('-');
  };

  var getNodeFromGroupId = function(group_id) {
    var num = COMBO_IDS_RANGE + group_id;
    return nodes_hash['N-' + num];
  };

  var getNode = function(node_key) {
    if (_.isNumber(node_key)) {
      node_key = node_key.toString();
    }
    var charatZero = node_key.charAt(0);
    if (charatZero !== 'N') {
      if (charatZero === 'G') {
        var num = COMBO_IDS_RANGE + parseInt(node_key.substring(2), 10);
        node_key = 'N-' + num;
      } else {
        node_key = nodeKeyFromId(node_key);
      }
    }
    return nodes_hash[node_key];
  };

  var isNodeCombo = function(node) {
    return (node.type === COMBO);
  };

  combineService.isNodeOpen = function (nodes, node) {
    return _.any(nodes, _.matches({ id: node.id, type: node.type }));
  };

  // ------------ Links -----------------------------------
  var linkKeyFromIds = function(from_id, to_id) {
    return ['L', from_id, to_id].join('-');
  };

  var linkKey = function(link) {
    return linkKeyFromIds(link.from_id, link.to_id);
  };

  var getLink = function(link_key) {
    return links_hash[link_key];
  };

  var createLinksHashByFromIdAndToId = function(links) {
    var res = {};
    var key = null;
    if (links === undefined || links === null) {return res;}
    _.forEach(links, function(val) {
      key = linkKey(val);
      res[key] = val;
    });
    combineService.priv.links_hash = res;
    return res;
  };
// ============== End Hash Function ==================================================== //

//================= Prepare Indexes ==================================================== //

  ////////////////////////////////////////////////////////
  // The reason to augment the links to the nodes is that
  //   later on it is much faster to access them as direct
  //   references from their nodes.
  ////////////////////////////////////////////////////////
  var links_added = false;
  function augmentLinkReferencesToEmps(nodes, links) {
    logger("In augmentLinkReferencesToEmps()");
    if (links_added) { return; }

    // And add nodes to the golbal hash table
    _.forEach(nodes, function(node) {
      var node_key = nodeKey(node);
      nodes_hash[node_key] = node;
    });

    var tmp_to_links   = {};
    var tmp_from_links = {};

    // Prepare lists of links
    _.forEach(links, function(link) {

      var tokey = nodeKeyFromId(link.to_id);
      var to_list = tmp_to_links[tokey];
      if (to_list === undefined) {
        to_list = [];
        tmp_to_links[tokey] = to_list;
      }
      to_list.push( linkKey(link) );

      var fromkey = nodeKeyFromId(link.from_id);
      var from_list = tmp_from_links[fromkey];
      if (from_list === undefined) {
        from_list = [];
        tmp_from_links[fromkey] = from_list;
      }
      from_list.push( linkKey(link) );

      // Now also add the link to the global hash table
      var link_key = linkKey(link);
      links_hash[link_key] = link;
    });

    // Add the links lists to the nodes
    _.forEach(nodes, function(node) {
      var node_key = nodeKey(node);
      node.to_links   = ( tmp_to_links[ node_key ]   === undefined ? [] : tmp_to_links[node_key] );
      node.from_links = ( tmp_from_links[ node_key ] === undefined ? [] : tmp_from_links[node_key] );
    });

    links_added = true;
    return;
  }

  //////////////////////////////////////////////////////////////////////////////////////////////
  // Prepare references to nodes from the groups. Handles both hierarchical groups (structure)
  //   as well as groups from a flat structure like age and office
  //////////////////////////////////////////////////////////////////////////////////////////////
  var group_nodes_refs_prepared = false;
  function prepareGroupNodesReferences(nodes, groups) {
    logger("In prepareGroupNodesReferences()");

    if (group_nodes_refs_prepared) { return; }

    _.forEach(nodes, function(node) {
      if ( isNodeCombo(node) ) { return; }
      var containing_group;
      if (node.group === null) {
        containing_group = _.find(groups, function (e) {
          return e.value === 'NA';
        });
        if (!containing_group) {
          containing_group = {
            value: 'NA',
            parent: null,
            name: 'NA'
          };
          groups.push(containing_group);
        }
      } else {
        containing_group = _.find(groups, function(e) {
          if (typeof e === 'object') {
            if (node.group !== undefined) {
              return (e.value === node.group);
            }
            return 'NA';
          }
          return e === node.group;
        });
      }
      // This odd looking line is here because the group may be an object (structure)
      // or a string (age, gender ..)
      if (!containing_group && node.group === 'NA') {
        containing_group = {
          value: 'NA',
          parent: null,
          name: 'NA'
        };
        groups.push(containing_group);
      }
      containing_group = typeof containing_group === 'object' ? containing_group : getGroup(containing_group);

      node.containing_group_ref = groupKey(containing_group);
      var son_nodes_refs = containing_group.son_nodes_refs_list;
      if (son_nodes_refs === undefined) {
        son_nodes_refs = [];
        containing_group.son_nodes_refs_list = son_nodes_refs;
      }
      son_nodes_refs.push( nodeKey(node) );
      node.display = true;
      node.sons_count = 1;
      node.overlay_entity_type = containing_group.overlay_entity_type_name;
    });
    group_nodes_refs_prepared = true;
    return;
  }

  priv.calculateGroupCardinality = function(group) {
    logger('In calculateGroupCardinality() - working on group: ', group.value);
    var cardinality    = (group.son_nodes_refs_list === undefined) ? 0 : group.son_nodes_refs_list.length;
    var son_groups_arr = group.son_groups_refs_list;
    _.forEach(son_groups_arr, function(gkey) {
      var son_group = getGroup(gkey);
      if (son_group.cardinality !== undefined) { cardinality += son_group.cardinality; }
      if (son_group.cardinality === undefined) {
        cardinality += priv.calculateGroupCardinality(son_group, groups_hash);
      }
    });
    return cardinality;
  };

  priv.calculateAllGroupsCardinality = function() {
    logger('In calculateAllGroupsCardinality()');
    _.forEach(groups_hash, function(g) {
      g.cardinality = priv.calculateGroupCardinality(g,groups_hash);
    });
    return groups_hash;
  };

  ////////////////////////////////////////////////////////
  // Preparing a tree structure of references in order to
  //   speed up acess to the strucutre
  ////////////////////////////////////////////////////////
  var groups_tree_prepared = false;
  function prepareGroupReferencesTree(groups) {
    logger("In prepareGroupReferencesTree()");
    if (groups_tree_prepared) { return; }
    var new_groups = _.clone(groups);
    _.forEach(new_groups, function(g, i) {

      var gg = typeof g === 'object' ? g : {value: g, parent: null, name: g};
      var parent = _.find(groups, {value: gg.parent});
      gg.parent_ref = parent ? groupKey(parent) : null;
      var refs               = _.filter(groups, {parent: gg.value} );
      gg.son_groups_refs_list = _.map(refs, function(e) {return groupKey(e); });
      gg.son_nodes_refs_list = [];
      gg.internal_index = i;
      groups_hash[groupKey(gg)] = gg;
    });
    groups_tree_prepared = true;
    return;
  }

  priv.createOverlayGroups = function(external_nodes) {
    logger("In: createOverlayGroups()");
    var external_groups = [];
    _.forEach(external_nodes, function(n) {
      n.group = n.overlay_entity_group_name;
      var g = {
        value: n.overlay_entity_group_name,
        parent: null,
        type: OVERLAY_ENTITY,
        name: n.overlay_entity_group_name,
        overlay_entity_type: n.overlay_entity_type_name
      };
      if (!_.find(external_groups, {name: g.name})) { external_groups.push(g); }
    });
    return external_groups;
  };

  priv.prepareDataStructures = function(nodes, links, group_by, group_value) {
    logger("In: prepareDataStructures()");
    angular.noop(group_value);
    augmentLinkReferencesToEmps(nodes, links);

    var external_nodes = _.filter(nodes, {type: OVERLAY_ENTITY});
    var external_groups = priv.createOverlayGroups(external_nodes);
    var groups = _.union(group_by.values, external_groups);
    groups = _.filter(groups, function(e) { return e !== null; });
    prepareGroupReferencesTree(groups);
    prepareGroupNodesReferences(nodes, groups);
    if (!links_hash) { links_hash = createLinksHashByFromIdAndToId(links); }
    priv.calculateAllGroupsCardinality();
  };

//============= End Prepare Indexes ==================================================== //

//============= End Creators =========================================================== //
  priv.createNewLink = function(from_id, from_type, to_id, to_type, weight, inner) {
    var new_link = {
      from_id: from_id,
      from_type: from_type,
      to_id: to_id,
      to_type: to_type,
      way_arr: false,
      weight: weight,
      inner_links: inner
    };
    return new_link;
  };

  priv.createCombo = function create_combo(group) {
    logger("In: createCombo() for group: ", group);
    var id = COMBO_IDS_RANGE + group.value;
    var combo = getNode(id);
    var containing_group_ref = (group.parent === null ? null : groupKeyFromId(group.parent));
    if (combo === undefined) {
      var combo_type = 'single';
      if (group.type === "overlay_entity") { combo_type = 'overlay_entity'; }
      combo =  {
        id: COMBO_IDS_RANGE + group.value,
        type: 'combo',
        combo_type: combo_type,
        image_url: undefined,
        group_type: group.name,
        rate: null,
        color: group.color,
        display: true,
        name: group.name,
        containing_group_ref: containing_group_ref,
        combo_group_ref: groupKey(group),
        to_links: [],
        from_links: [],
        sons_count: 0,
        contained_nodes_refs: [],
        overlay_entity_type: group.overlay_entity_type
      };
    }

    nodes_hash[nodeKey(combo)] = combo;
    var parent_group = groups_hash[group.parent_ref];
    if (parent_group !== undefined) {
      parent_group.son_nodes_refs_list.push( nodeKey(combo) );
    }
    return combo;
  };
//============= End Creators =========================================================== //

//============= The mess starts here =================================================== //
  priv.isAncestor = function(descendant_key, ancestor_key) {
    logger("isAncestor(), ", descendant_key, " and ", ancestor_key);
    if (!descendant_key)                        {return false;}
    if (descendant_key === ancestor_key)        {return true;}

    var descendant = getGroup(descendant_key);
    if (descendant.parent_ref === ancestor_key) {return true;}
    if (!descendant.parent_ref)    {return false;}
    return priv.isAncestor(descendant.parent_ref, ancestor_key);
  };

  priv.link_is_an_inner_link = function(link, combine_root) {
    logger("link_is_an_inner_link() for link: ", linkKey(link), ", combine_root: ", combine_root);
    var toNode   = getNode(link.to_id);
    var fromNode = getNode(link.from_id);
    if (!fromNode || !toNode) {return true;}
    var combine_root_group_key = getNode(combine_root).combo_group_ref;
    var ret1 = priv.isAncestor( toNode.containing_group_ref,   combine_root_group_key);
    var ret2 = priv.isAncestor( fromNode.containing_group_ref, combine_root_group_key);
    return ret1 && ret2;
  };

  ////////////////////////////////////////////////////////////////
  // Will look if there's already an existing link between node
  //   and combo. If not will create a new one and return it.
  ////////////////////////////////////////////////////////////////
  priv.createOrGetComboLink = function(from_id, from_type, to_id, to_type, links) {
    logger("In createOrGetComboLink() - from_id: ", from_id, " from_type: ", from_type, ", to_id: ", to_id, " to_type: ", to_type);
    var link_key = linkKeyFromIds(from_id, to_id);
    var new_link = links_hash[link_key];
    if (new_link === undefined) {
      new_link = priv.createNewLink(from_id, from_type, to_id, to_type, 0, []);
    }

    logger("new_link: ", new_link);
    links.push(new_link);
    links_hash[link_key] = new_link;
    return new_link;
  };

  priv.findAllSonNodes = function(curr_group, son_nodes) {
    logger("In findAllSonNodes() for group: ", curr_group.value);
    var ret_son_nodes = _.clone(son_nodes);
    var contained_nodes = curr_group.son_nodes_refs_list;
    var son_groups_refs = curr_group.son_groups_refs_list;

    _.forEach(contained_nodes, function(node_key) {
      var node = getNode(node_key);
      ret_son_nodes[nodeKey(node)] = 1;
    });

    _.forEach(son_groups_refs, function(group_key) {
      var group = getGroup(group_key);
      ret_son_nodes = _.assign( ret_son_nodes, priv.findAllSonNodes(group, ret_son_nodes) );
    });
    return ret_son_nodes;
  };

  function hideAllNodes(nodes_list) {
    var ret_nodes_list = _.clone(nodes_list);
    _.forEach(ret_nodes_list, function(v,k) {
      angular.noop(v);
      var node = getNode(k);
      logger("Hideing node: ", k);
      node.display = false;
    });
    return ret_nodes_list;
  }

  function highestVisibleParentByGroup(group_id, visible_node) {
    var group = getGroup(group_id);
    var node  = getNodeFromGroupId(group_id);

    if (node !== undefined && node.display === true) { visible_node = node; }
    if (group.parent === null) { return visible_node; }

    var ret =  highestVisibleParentByGroup(group.parent, visible_node);
    logger("group: ", group_id, " returning: ", (ret === null ? 'null' : ret.id) );
    return ret;
  }

  priv.highestVisibleParentByNode = function(node_id) {
    logger("In highestVisibleParentByNode() for node: ", node_id);
    var node = getNode(node_id);
    var group_key = node.containing_group_ref;
    var node_is_visible = node.display;
    var containing_group = getGroup(group_key);
    var visible_node = null;
    if (node_is_visible) { visible_node = node; }

    return highestVisibleParentByGroup(containing_group.value, visible_node);
  };

  priv.reasignLinksOfNode = function(node, id_to_reasign_to, touched_links_list, links) {
   logger("In reasignLinksOfNode for node: ", node.id, ", id_to_reasign_to: ", id_to_reasign_to);
    if (node.type === 'combo') { return touched_links_list; }

    var to_links = _.clone(node.to_links);
    _.forEach(to_links, function(lkey) {
      logger("handling to_list, lkey: ", lkey);
      var link_to_hide = getLink(lkey);
      if (priv.link_is_an_inner_link(link_to_hide, id_to_reasign_to)) { return; }
      var from_node = priv.highestVisibleParentByNode(link_to_hide.from_id);
      if (from_node !== null) {
        logger("Found from_node: ", from_node.id);
        var visible_link = priv.createOrGetComboLink(from_node.id, from_node.type, id_to_reasign_to, 'combo', links);
        visible_link.inner_links = _.union( visible_link.inner_links, [linkKey(link_to_hide)] );
        touched_links_list = _.union(touched_links_list, [ visible_link] );
      }
    });

    var from_links = _.clone(node.from_links);
    _.forEach(from_links, function(lkey) {
      logger("handing from_list, lkey: ", lkey);
      var link_to_hide = getLink(lkey);
      if (priv.link_is_an_inner_link(link_to_hide, id_to_reasign_to)) { return; }
      var to_node = priv.highestVisibleParentByNode(link_to_hide.to_id);
      if (to_node !== null) {
        logger("Found visible node: ", to_node, " for highestVisibleParentByNode() of: ", link_to_hide.to_id);
        var visible_link = priv.createOrGetComboLink(id_to_reasign_to, 'combo', to_node.id, to_node.type, links);
        visible_link.inner_links = _.union(visible_link.inner_links, [linkKey(link_to_hide)] );
        logger("visible_link: ", visible_link);
        touched_links_list = _.union(touched_links_list, [ visible_link] );
      }
    });
    return touched_links_list;
  };

  priv.reassignLinksFromNodesListToVisibleLinks = function(nodes_list, id_to_reassign_to, links) {
    logger("In reasign_links_from_nodes_list_to_visible_links with id_to_reasign_to: ", id_to_reassign_to);
    var touched_links_list = [];
    logger(nodes_list);
    _.forEach(nodes_list, function(v, node_key) {
      angular.noop(v);
      var node = getNode(node_key);
      touched_links_list = priv.reasignLinksOfNode(node, id_to_reassign_to, touched_links_list, links);
    });
    return touched_links_list;
  };

  priv.reasignLinksFromComboToParentNode = function(node, touched_links_list, links) {
    logger("In reasignLinksFromComboToParentNode() for node: ", node.id);
    logger(node);
    if (node.type === 'combo') { return touched_links_list; }

    var to_links = _.clone(node.to_links);
    _.forEach(to_links, function(lkey) {
      logger("to_list, lkey: ", lkey);
      var link_to_hide = getLink(lkey);
      var from_node = priv.highestVisibleParentByNode(link_to_hide.from_id);
      var visible_link = priv.createOrGetComboLink(from_node.id, from_node.type, node.id, node.type, links);
      visible_link.inner_links = _.union( visible_link.inner_links, [linkKey(link_to_hide)] );
      touched_links_list = _.union(touched_links_list, [ visible_link] );
    });

    var from_links = _.clone(node.from_links);
    _.forEach(from_links, function(lkey) {
      logger("from_list, lkey: ", lkey);
      var link_to_hide = getLink(lkey);
      var to_node = priv.highestVisibleParentByNode(link_to_hide.to_id);
      logger("Found visible node: ", to_node, " for highestVisibleParentByNode() of: ", link_to_hide.to_id);
      var visible_link = priv.createOrGetComboLink(node.id, node.type, to_node.id, to_node.type, links);
      visible_link.inner_links = _.union(visible_link.inner_links, [linkKey(link_to_hide)] );
      touched_links_list = _.union(touched_links_list, [ visible_link] );
    });
    return touched_links_list;
  };

  function reassignLinksFromComboToSonNodes(son_nodes_list, links) {
    logger("In reassignLinksFromComboToSonNodes()");
    var touched_links_list = [];
    _.forEach(son_nodes_list, function(node_key) {
      var node = getNode(node_key);
      touched_links_list = priv.reasignLinksFromComboToParentNode(node, touched_links_list, links);
    });
    return touched_links_list;
  }

  function containingGroupCardinality(node_id) {
    var node = getNode(node_id);
    var group_key;

    if ( isNodeCombo(node) ) {
      group_key = node.combo_group_ref;
      return getGroup(group_key).cardinality;
    }
    return 1;
  }

  function isLinkSingleToSingle(link_key) {
    var link = getLink(link_key);
    var from_node = getNode(link.from_id);
    if (isNodeCombo(from_node)) { return false; }
    var to_node = getNode(link.to_id);
    if (isNodeCombo(to_node)) { return false; }
    return true;
  }

  function recalculateLinksWeights(links_list, measure_type) {
    logger("In recalculateLinksWeights");
    if (links_list === undefined) { return; }
    _.forEach( links_list, function(link) {
      var weight = 0;
      logger("Working on link: ", linkKey(link));
      _.forEach( link.inner_links, function(inner_key) {
        if ( isLinkSingleToSingle(inner_key) ) {
          var inner_link = getLink(inner_key);
          logger("inner link key: ", inner_key, " with weight: ", inner_link.weight);
          weight += inner_link.weight;
        }
      });

      var count = -1;
      if (measure_type !== EMAILS) {
        weight *= 5;
        var from_group_count = containingGroupCardinality(link.from_id);
        var to_group_count   = containingGroupCardinality(link.to_id);
        count = from_group_count * to_group_count;
        link.weight = Math.round(weight / count, 10) + 1;
      } else {
        count = _.filter(link.inner_links, function(l) {
          return (getLink(l).to_type !== COMBO && getLink(l).from_type !== COMBO);
        }).length;
        link.weight = Math.round(weight / count, 10) ;
      }
    });
  }

  priv.breakSymetry = function(id1, id2) {
    if (id1 > id2) { return true; }
    if (typeof id1 === 'string') {return true;}
    return false;
  };

  priv.markBidirectionalLinks = function(links_list) {
    logger("In markBidirectionalLinks()");
    if (links_list === undefined) { return; }
    _.forEach( links_list, function(link) {
      var reciprocal_link = getLink(linkKeyFromIds(link.to_id, link.from_id));
      if (!reciprocal_link)                       { return; }
      if (reciprocal_link.weight !== link.weight) { return; }
      if (priv.breakSymetry(link.from_id, reciprocal_link.from_id)) { return; }
      link.way_arr = true;

      reciprocal_link.remove = true;
    });
    return links_list;
  };

// ======================== The mess ends about here .. =================== //
  priv.uniqueLinksArray = function(links) {
    logger("uniqing");
    var link;
    var tmp_links_hash = {};
    while (links.length) {
      link = links.pop();
      tmp_links_hash[linkKey(link)] = link;
    }
    _.forEach(tmp_links_hash, function(l) { links.push(l); });
    return links;
  };

  function combine(links, group_value) {
    logger("In combine for group: ", group_value);
    if (group_value === undefined) { group_value = 'NA'; }
    var curr_group    = getGroup(group_value);
    var curr_combo    = priv.createCombo(curr_group);
    var all_son_nodes = priv.findAllSonNodes(curr_group, {});
    logger("all_son_nodes: ", all_son_nodes);
    curr_combo.display = true;
    all_son_nodes     = hideAllNodes(all_son_nodes);
    var touched_links = priv.reassignLinksFromNodesListToVisibleLinks(all_son_nodes, curr_combo.id, links );

    var rate = 0;
    curr_combo.sons_count = 0;
    _.each(all_son_nodes, function(v,node_key) {
      angular.noop(v);
      var node = getNode(node_key);
      rate += node.rate;
      curr_combo.sons_count += node.sons_count;
    });
    rate /= all_son_nodes.length;
    curr_combo.rate = isNaN(rate) ? 0 : rate;
    priv.uniqueLinksArray(links);

    return touched_links;
  }

  function combineAll(links, group_value) {
    logger("In combineAll() for group_value: ", group_value);
    _.forEach(nodes_hash, function(v) {
      v.display = false;
    });
    if (group_value === undefined) { group_value = 'NA'; }
    var curr_group     = getGroup(groupKeyFromId(group_value));
    var curr_combo     = priv.createCombo(curr_group);
    curr_combo.display = true;

    var touched_links = [];
    _.forEach(groups_hash, function(g,k) {
      logger('Going to combine group: ', g.value, ' with type: ', g.type);
      angular.noop(k);
      if (g.type === OVERLAY_ENTITY) {
        touched_links = _.union( combine(links, g.value), touched_links);
      }
    });
    return touched_links;
  }

  priv.uncombine = function uncombine(links, group_value, curr_combo, measure_type) {
    logger("In uncombine for group: ", group_value);
    var curr_group     = getGroup(group_value);
    curr_combo.display = false;

    var direct_son_nodes = curr_group.son_nodes_refs_list;
    _.forEach(direct_son_nodes, function(n) {
      logger("Working on node: ", n);
      var node = getNode(n);
      node.display = true;
    });
    var son_groups = curr_group.son_groups_refs_list;

    logger("son_groups: ", son_groups);
    var touched_links = [];
    _.forEach(son_groups, function(g) {
      logger("Going to combine subgoup: ", g);
      var group = getGroup(g);
      touched_links = _.union(touched_links, combine(links, group.value));
    });

    touched_links = _.union(touched_links, reassignLinksFromComboToSonNodes(direct_son_nodes, links));
    recalculateLinksWeights(touched_links, measure_type);
    priv.markBidirectionalLinks(links);
    priv.uniqueLinksArray(links);
  };

  function getOnlyNodesInDisplay(nodes) {
    logger("In getOnlyNodesInDisplay()");
    while (nodes.length) { nodes.pop(); }
    _.forEach(nodes_hash, function(v) {
      var show_node = (v.display === true);
      if (isNodeCombo(v)) {
        var group = getGroup(v.combo_group_ref);
        show_node = show_node && (group.cardinality > 0);
      }
      if (show_node) { nodes.push(v); }
    });
    return nodes;
  }

  // ========================= API ===============================//
  combineService.handleBidirectionalLinks = function(nodes, links_list, group_by) {
    logger('In: handleBidirectionalLinks');
    priv.prepareDataStructures(nodes, links_list, group_by, null);
    priv.markBidirectionalLinks(links_list);
  };

  //////////////////////////////////////////////////////
  // Group one node
  //////////////////////////////////////////////////////
  combineService.collapseBranchByGroupValue = function (nodes, links, measure_type, group_by, group_value) {
    logger("In: collapseBranchByGroupValue() - measure_type: ", measure_type);
    priv.prepareDataStructures(nodes, links, group_by, group_value);
    var touched_links = combine(links, group_value);
    recalculateLinksWeights(touched_links, measure_type);
    priv.markBidirectionalLinks(links);
    getOnlyNodesInDisplay(nodes);
  };

  //////////////////////////////////////////////////////
  // Group all the way
  //////////////////////////////////////////////////////
  combineService.collapseAllByGroupValue = function (nodes, links, measure_type, group_by, group_value) {
    logger("In collapseAllByGroupValue for group: ", group_value, measure_type);
    if (group_value === undefined) { group_value = 'NA'; }
    angular.noop(measure_type);
    priv.prepareDataStructures(nodes, links, group_by, group_value);
    var touched_links = combineAll(links, group_value );
    recalculateLinksWeights(touched_links, measure_type);
    priv.markBidirectionalLinks(links);
    getOnlyNodesInDisplay(nodes);
  };

  combineService.collapseAllBranchsByGroupValue = function (nodes, links, measure_type, group_by) {
    logger("In: collapseAllBranchsByGroupValue() - measure_type: ", measure_type);
    priv.prepareDataStructures(nodes, links, group_by, null);
    var touched_links = [];

    var group_values = _.map(groups_hash, function(g) { return g.value; });
    _.forEach(group_values, function(group_value) {
      touched_links = _.union(touched_links, combine(links, group_value));
    });

    recalculateLinksWeights(touched_links, measure_type);
    priv.markBidirectionalLinks(links);
    getOnlyNodesInDisplay(nodes);
  };

  //////////////////////////////////////////////////////
  // Ungroup a single combo
  //////////////////////////////////////////////////////
  combineService.ungroupComboOnceById = function (nodes, combo_id, links, measure_type) {
    logger("In: ungroupComboOnceById for combo: ", combo_id);
    angular.noop(nodes);
    var curr_combo = getNode( combo_id );
    logger("Group of curr_combo: ", curr_combo.combo_group_ref );
    var curr_group = getGroup( curr_combo.combo_group_ref );
    try {
      priv.uncombine(links, curr_group.value, curr_combo, measure_type);
    } catch(ex) {
      console.error("caught exception with error message: ", ex.message);
      console.error(ex);
      //throw ex;
    }
    var ret_nodes = getOnlyNodesInDisplay(nodes);
    return ret_nodes;
  };

  //////////////////////////////////////////////////////
  // Ungroup everything under a given combo
  //////////////////////////////////////////////////////
  combineService.recursivelyUngroupCombo = function () {
    logger("In: recursivelyUngroupCombo");
    _.forEach(nodes_hash, function(n) {
      if (n.type === COMBO) {
        n.display = false;
      } else {
        n.display = true;
      }
    });

    var touched_links = [];
    _.forEach(links_hash, function(l) {
      touched_links.push(l);
    });

    touched_links = priv.markBidirectionalLinks(touched_links);
    var ret_nodes = getOnlyNodesInDisplay([]);
    return [_.clone(ret_nodes), _.clone(touched_links)];
  };

  //////////////////////////////////////////////////////
  // Return all sons under given group
  //////////////////////////////////////////////////////
  combineService.recursivelyGetSinglesInsideCombo = function(node) {
    logger("In recursivelyGetSinglesInsideCombo(), with node: ", node.id);
    if ( !isNodeCombo(node) ) {return [];}
    var group = getGroup(node.combo_group_ref);
    return _.map(priv.findAllSonNodes(group, {}), function (v, nkey) {
      angular.noop(v);
      return getNode(nkey);
    });
  };

  combineService.recursivelyGetEverythingInsideCombo = function (combo) {
    var node_keys = combineService.recursivelyGetSinglesInsideCombo(combo);
    return _.union(node_keys, combineService.getSubCombos(combo));
  };

  combineService.getSubCombos = function (combo) {
    var sub_combo_keys = getGroup(combo.combo_group_ref).son_groups_refs_list;
    return _.map(sub_combo_keys, function (key) {
      var group = getGroup(key);
      return {
        id: COMBO_IDS_RANGE + group.value,
        type: 'combo',
        name: group.name };
    });
  };

  combineService.comboContainingNode = function (nodes, node) {
    var combos = _.where(nodes, { type: 'combo' });
    return _.find(combos, function (combo) {
      var inner = combineService.recursivelyGetEverythingInsideCombo(combo);
      return _.any(inner, _.matches({ id: node.id, type: node.type }));
    });
  };

  //////////////////////////////////////////////////////
  // Reset combine data structures
  //////////////////////////////////////////////////////
  combineService.resetData = function () {
    logger("In resetData");
    links_added = false;
    group_nodes_refs_prepared = false;
    groups_tree_prepared = false;
    links_hash    = {};
    nodes_hash    = {};
    groups_hash   = {};
    combineService.priv.links_hash = links_hash;
  };

  //////////////////////////////////////////////////////
  // Utilities
  //////////////////////////////////////////////////////
  combineService.getLinkOriginNode = function(link_ref) {
    var link = typeof link_ref === 'string' ? getLink(link_ref) : link_ref;
    if (!link) {return undefined;}
    return( getNode(link.from_id));
  };

  combineService.getLinkDestinationNode = function(link_ref) {
    var link = typeof link_ref === 'string' ? getLink(link_ref) : link_ref;
    if (!link) {return undefined;}
    return( getNode(link.to_id));
  };

  combineService.highestVisibleParentByGroup = function (group_id, visible_node) {
    return highestVisibleParentByGroup(group_id, visible_node);
  };

  combineService.calculateComboRate = function(combo) {
    var sons = combineService.recursivelyGetSinglesInsideCombo( combo );
    if (sons.length === 0) { return 0; }
    var sum = _.sum(sons, 'rate');
    var res = Math.round(sum / sons.length) / 10;
    return parseFloat(res.toFixed(1));
  };

  combineService.calculateComboStandardDeviation =function(combo) {
    var mean = combineService.calculateComboRate(combo);
    var sons = combineService.recursivelyGetSinglesInsideCombo( combo );
    if (sons.length === 0) { return 0; }
    var sum  = _.sum(sons, function (node) {
      return Math.pow(node.rate - mean, 2);
    });
    var std = Math.sqrt(sum / (sons.length)) * 100;
    var res = Math.round(std) / 1000;
    return parseFloat(res.toFixed(1));
  };

  //==============================================================================================================
  return combineService;
});
