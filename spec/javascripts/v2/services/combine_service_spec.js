/*globals angular, describe, beforeEach, inject,it, expect,xit, _, spyOn*/

describe('combineService', function () {
  'use strict';

  var SINGLE = 'single',
      COMBO = 'combo',
      OVERLAY_ENTITY = 'overlay_entity';

  var EMAILS = 'Communication Flow';

  beforeEach(angular.mock.module('workships.services'));

  var service;
  var priv = null;
  var osize = function(o) {
    return Object.keys(o).length;
  };

  beforeEach(inject(function (combineService) {
    service = combineService;
    priv = service.priv;
  }));

  function pp(arr) {
    console.log('--------------------');
    _.forEach(arr, function(e) {
      console.log(e);
    });
    console.log('--------------------');
  }
  angular.noop(pp);

  describe('collapseBranchByGroupValue', function () {
    describe('when there\'s a direct child node to each group under the root node', function () {
      var nodes, links, measure_type, group_by;

      describe('when several groups on each level', function () {
        var setData;

        beforeEach(function () {
          setData = function () {
            nodes = [{ id: 1, type: SINGLE, group: 1 },
            { id: 2, type: SINGLE, group: 2 },
            { id: 3, type: SINGLE, group: 3 },
            { id: 4, type: SINGLE, group: 4 }];
            links = [{from_id: 3, from_type: SINGLE, to_id: 4, to_type: SINGLE, weight: 5}];
          };
          setData();
          measure_type = 1;
          group_by = {
            recursive: true,
            values: [{ value: 1, parent: null, name: 'I' },
            { value: 2, parent: 1, name: 'II' },
            { value: 3, parent: 1, name: 'III' },
            { value: 4, parent: 2, name: 'IV' }]
          };
        });

       it('should collapse all', function () {
          service.collapseBranchByGroupValue(nodes, links, measure_type, group_by, nodes[0].group);
          expect(nodes.length).toEqual(1);
        });

       it('should create a same amount of links no matter what the order of grouping', function () {
          setData();
          var group_by2 = {
            recursive: true,
            values: [{ value: 1, parent: null, name: 'I' },
              { value: 3, parent: 1, name: 'III' },
              { value: 2, parent: 1, name: 'II' },
              { value: 4, parent: 2, name: 'IV' }]
          };
          service.collapseBranchByGroupValue(nodes, links, measure_type, group_by2, nodes[0].group);
          expect(links.length).toEqual(1);
        });
      });
    });
  });

  describe('collapseBranchByGroupValue 2', function () {
    var nodes, links, group_by, measure_type;

    beforeEach(function () {
      group_by = { recursive: true, values: [
        { parent: null, value: 0 },
        { parent: 0, value: 1 },
        { parent: 1, value: 2 }] };
      measure_type = 1;
      links = [];
    });

    describe('if every group has direct single', function () {
      beforeEach(function () {
        nodes = [{ id: 1, type: SINGLE, group: 1 },
        { id: 2, type: SINGLE, group: 2 },
        { id: 3, type: SINGLE, group: 3 },
        { id: 4, type: SINGLE, group: 4 }];
        group_by = { id: 4, display: 'Structure', name: 'group_id', recursive: true, values: [
          { value: 1, parent: null, name: 1 },
          { value: 2, parent: 1, name: 2 },
          { value: 3, parent: 2, name: 3 },
          { value: 4, parent: 2, name: 4 }]
        };
      });

     it('should run', function () {
        service.collapseBranchByGroupValue(nodes, links, measure_type, group_by, 1);
        expect(nodes.length).toEqual(1);
      });
    });
  });

  describe('groupNodesOnce', function () {
    var nodes, links, group_by;

    describe('complex cases', function () {
      beforeEach(function () {
        group_by = { values: [1, 2] };
      });

     it('should create single-to-combo link with correct weight when first combining the to_single', function () {
      /*
        _           _
      /   \       /   \
      \ _ /       \ _ /
          \    =>    \\     <---| weight should be 6
          _\|_       _\\|   <---|
           /   \       / c \
           \ _ /       \ _ /
      */
        nodes = [{ id: 1, type: SINGLE, group: 1 },
                 { id: 2, type: SINGLE, group: 2 }];
        links = [{ from_id: 1, from_type: SINGLE, to_id: 2, to_type: SINGLE, weight: 1, way_arr: false  }];
        service.collapseBranchByGroupValue(nodes, links, 1, group_by, 2);

        expect(links.length).toEqual(2);
        expect(_.find(links, { from_id: 1, to_id: 100002 }).weight).toEqual(6);
      });

     it('should create single-to-combo link with correct weight when first combining the from_single, then to_single', function () {
      /*
        _           _            _           _
      /   \       / c \        / c \       /   \
      \ _ /       \ _ /  *here \ _ /       \ _ /
          \    =>     \  * =>      \    =>     \\      <---| weight should be 6
          _\|_        _\|_         _\|_        _\\|_   <---|
           /   \       /   \        / c \       / c \
           \ _ /       \ _ /        \ _ /       \ _ /

      */
        nodes = [{ id: 1, type: SINGLE, group: 1 },
                 { id: 2, type: SINGLE, group: 2 }];
        links = [{ from_id: 1, from_type: SINGLE, to_id: 2, to_type: SINGLE, weight: 1, way_arr: false  }];

        // combine group #1
        service.collapseBranchByGroupValue(nodes, links, 1, group_by, 1);

        // combine group #2
        service.collapseBranchByGroupValue(nodes, links, 1, group_by, 2);

        // uncombine group #1
        service.ungroupComboOnceById(nodes, 100001, links, 1);

        expect(links.length).toEqual(4);
        var link = _.find(links, { from_id: 1, to_id: 100002 });
        expect(link.weight).toEqual(6);
        expect(link.inner_links[0]).toEqual('L-1-2');
      });
    });
  });

  describe('Tests for the new combine', function () {
   it('Check grouping when there are no nodes', function () {
      var nodes = [
        { id: 1, type: SINGLE, group: 1 },
        { id: 2, type: SINGLE, group: 2 },
        { id: 3, type: SINGLE, group: 2 }];
      var links = [
        {from_id: 1, from_type: SINGLE, to_id: 2, to_type: SINGLE, weight: 5},
        {from_id: 1, from_type: SINGLE, to_id: 3, to_type: SINGLE, weight: 2},
      ];
      var group_by = {
        recursive: true,
        values: [
          { value: 1, parent: null, name: 'I' },
          { value: 2, parent: 1, name: 'II' }
      ]};
      service.collapseBranchByGroupValue(nodes, links, EMAILS, group_by, 2);
      var link_new = _.find(links, function(l) { return l.from_id === 1 && l.to_id === 100002; });
      expect(link_new.weight).toEqual(4);
    });

   it('combine all and ungroup once a group with 3 subgroups', function () {
      var nodes = [
        { id: 1, type: SINGLE, group: 2 },
        { id: 2, type: SINGLE, group: 2 },
        { id: 3, type: SINGLE, group: 3 },
        { id: 4, type: SINGLE, group: 4 },
        { id: 5, type: SINGLE, group: 4 }];
      var links = [
        {from_id: 3, from_type: SINGLE, to_id: 2, to_type: SINGLE, weight: 1},
        {from_id: 4, from_type: SINGLE, to_id: 2, to_type: SINGLE, weight: 1},
        {from_id: 5, from_type: SINGLE, to_id: 2, to_type: SINGLE, weight: 1},
      ];
      var group_by = {
        recursive: true,
        values: [
          { value: 1, parent: null, name: 'I' },
          { value: 2, parent: 1, name: 'II' },
          { value: 3, parent: 1, name: 'III' },
          { value: 4, parent: 1, name: 'IV' },
      ]};
      service.collapseBranchByGroupValue(nodes, links, EMAILS, group_by, 1);
      service.ungroupComboOnceById(nodes, 100001, links, EMAILS);

      expect(nodes.length).toEqual(3);
      expect(nodes[0].id).not.toBeLessThan(100002);
    });

   it('combine all and ungroup once then ungroup allQQQQQQQQQQQQq', function () {
      var nodes = [
        { id: 1, type: SINGLE, group: 2 },
        { id: 2, type: SINGLE, group: 2 },
        { id: 3, type: SINGLE, group: 3 },
        { id: 4, type: SINGLE, group: 4 },
        { id: 5, type: SINGLE, group: 4 }];
      var links = [
        {from_id: 3, from_type: SINGLE, to_id: 2, to_type: SINGLE, weight: 1},
        {from_id: 4, from_type: SINGLE, to_id: 2, to_type: SINGLE, weight: 1},
        {from_id: 5, from_type: SINGLE, to_id: 2, to_type: SINGLE, weight: 1},
      ];
      var group_by = {
        recursive: true,
        values: [
          { value: 1, parent: null, name: 'I' },
          { value: 2, parent: 1, name: 'II' },
          { value: 3, parent: 1, name: 'III' },
          { value: 4, parent: 2, name: 'IV' },
      ]};
      service.collapseBranchByGroupValue(nodes, links, EMAILS, group_by, 1);
      service.ungroupComboOnceById(nodes, 100001, links, EMAILS);
      var res = service.recursivelyUngroupCombo(links, EMAILS);
      nodes = res[0];
      links = res[1];
      expect(nodes.length).toEqual(5);
      expect(links.length).toEqual(3);
    });
  });


  describe('Test private functions', function() {
    var nodes  = null,
        links  = null,
        groups = null;

    beforeEach( function() {
      priv = service.priv;
    });

    describe('createOrGetComboLink', function() {
      links = [];
      it('should create a new link', function() {
        priv.prepareDataStructures([], links, [], null);
        var new_link = priv.createOrGetComboLink(1,SINGLE,2,COMBO, links);
        expect(new_link.to_id).toEqual(2);
        expect( osize(priv.links_hash) ).toEqual(1);
      });

      it('should return an existing link', function() {
        var link = priv.createNewLink(1, SINGLE, 2, COMBO, 3, []);
        links.push(link);
        priv.prepareDataStructures([], links, [], null);
        expect( osize(priv.links_hash) ).toEqual(1);
        var new_link = priv.createOrGetComboLink(1,SINGLE,2,COMBO, links);
        expect(new_link.to_id).toEqual(2);
        expect( osize(priv.links_hash) ).toEqual(1);
      });
    });


    describe('uniqueLinksArray', function() {
      it('should return unique links array', function() {
        links = [
          {from_id: 17, from_type: SINGLE, to_id: 6, to_type: SINGLE, weight: 1},
          {from_id: 17, from_type: SINGLE, to_id: 6, to_type: SINGLE, weight: 1},
          {from_id: 8,  from_type: SINGLE, to_id: 3, to_type: SINGLE, weight: 1},
          {from_id: 16, from_type: SINGLE, to_id: 3, to_type: SINGLE, weight: 1},
          {from_id: 8,  from_type: SINGLE, to_id: 3, to_type: SINGLE, weight: 1}
        ];
        var retarr = priv.uniqueLinksArray(links);
        expect( retarr.length ).toEqual(3);
      });
    });

    describe('createOverlayGroups', function() {
     it('should create two overlay groups', function() {
        var external_nodes = [
          { id: 100, type: OVERLAY_ENTITY, name:"r1@poalim.co.il", overlay_entity_group_name:"poalim.co.il" },
          { id: 101, type: OVERLAY_ENTITY, name:"r2@poalim.co.il", overlay_entity_group_name:"poalim.co.il" },
          { id: 102, type: OVERLAY_ENTITY, name:"r3@acme.com",     overlay_entity_group_name:"acme.com" }
        ];
        var ext_groups = priv.createOverlayGroups(external_nodes);
        expect( ext_groups.length ).toEqual(2);
      });

     it('should be able to handle an empty input', function() {
        var ext_groups = priv.createOverlayGroups([]);
        expect( ext_groups.length ).toEqual(0);
      });
    });



    describe('markBidirectionalLinks()', function() {
      var setData = function() {
        links = [
          {from_id: 2, from_type: SINGLE, to_id: 4, to_type: SINGLE, weight: 1, way_arr: false, hide: false},
          {from_id: 4, from_type: SINGLE, to_id: 2, to_type: SINGLE, weight: 1, way_arr: false, hide: false},
          {from_id: 2, from_type: SINGLE, to_id: 5, to_type: SINGLE, weight: 1, way_arr: false, hide: false},
          {from_id: 4, from_type: SINGLE, to_id: 5, to_type: SINGLE, weight: 1, way_arr: false, hide: false},
          {from_id: 5, from_type: SINGLE, to_id: 4, to_type: SINGLE, weight: 2, way_arr: false, hide: false}
        ];
      };

      beforeEach( function() {
        setData();
      });

     it('Need to mark links correctly', function() {
        priv.prepareDataStructures([], links, [], null);
        priv.markBidirectionalLinks(links);
        expect( links[0].way_arr ).toEqual(true);
        expect( links[0].hide    ).toEqual(false);
        expect( links[1].remove  ).toEqual(true);
      });

     it('Hanlde a link with an overlay entity', function() {
        links.push({from_id: 2, from_type: SINGLE, to_id: '100000a', to_type: OVERLAY_ENTITY, weight: 1, way_arr: false, hide: false});
        links.push({from_id: '100000a', from_type: OVERLAY_ENTITY, to_id: 2, to_type: SINGLE, weight: 1, way_arr: false, hide: false});
        priv.prepareDataStructures([], links, [], null);
        priv.markBidirectionalLinks(links);
        expect( links[5].remove ).not.toBeDefined();
        expect( links[6].remove ).toEqual(true);
      });
    });



    describe('isAncestor() and link_is_an_inner_link()', function() {
      var setData = function() {
        nodes = [
          { id: 2, type: SINGLE, group: 2 },
          { id: 4, type: SINGLE, group: 4 },
          { id: 5, type: SINGLE, group: 5 }
        ];
        links = [
          {from_id: 2, from_type: SINGLE, to_id: 4, to_type: SINGLE, weight: 1},
          {from_id: 4, from_type: SINGLE, to_id: 5, to_type: SINGLE, weight: 1}
        ];
        groups = {
          values: [
            { value: 1, parent: null, name: 'I' },
            { value: 2, parent: 1,    name: 'II' },
            { value: 3, parent: 2,    name: 'III' },
            { value: 4, parent: 3,    name: 'IV' },
            { value: 5, parent: 1,    name: 'V' }
        ]};
      };

      beforeEach( function() {
        setData();
      });
     it('isAncestor', function() {
        priv.prepareDataStructures([], [], groups, null);
        expect( priv.isAncestor('G-4','G-2') ).toEqual(true);
        expect( priv.isAncestor('G-4','G-1') ).toEqual(true);
        expect( priv.isAncestor('G-4','G-5') ).toEqual(false);
        expect( priv.isAncestor('G-2','G-4') ).toEqual(false);
        expect( priv.isAncestor('G-2','G-2') ).toEqual(true);
      });

      it('link_is_an_inner_link', function() {
        nodes.push({id: 100002, type: COMBO, combo_type: 'single', image_url: undefined, group_type: 'g2', rate: 0, color: undefined, display: true, name: 'g2', containing_group_ref: 'NA', combo_group_ref: 'G-2', to_links: [], from_links: [], sons_count: 9, contained_nodes_refs: []});
        priv.prepareDataStructures(nodes, links, groups, null);
        var res = priv.link_is_an_inner_link(links[0], 'G-2');
        expect( res  ).toEqual(true);
        res = priv.link_is_an_inner_link(links[1], 'G-2');
        expect( res  ).toEqual(false);
      });
    });

    describe('groups cardinality', function() {
      var setData = function() {
        nodes = [
          { id: 1, type:  SINGLE, group: 1    },
          { id: 2, type:  SINGLE, group: 11   },
          { id: 3, type:  SINGLE, group: 11   },
          { id: 4, type:  SINGLE, group: 111  },
          { id: 5, type:  SINGLE, group: 111  },
          { id: 6, type:  SINGLE, group: 112  },
          { id: 7, type:  SINGLE, group: 112  },
          { id: 8, type:  SINGLE, group: 12   },
          { id: 9, type:  SINGLE, group: 12   },
          { id: 10, type: SINGLE, group: 13   },
          { id: 11, type: SINGLE, group: 13   },
          { id: 12, type: SINGLE, group: 131  },
          { id: 13, type: SINGLE, group: 132  },
          { id: 14, type: SINGLE, group: 132  },
          { id: 15, type: SINGLE, group: 1311 },
          { id: 16, type: SINGLE, group: 1311 },
          { id: 17, type: SINGLE, group: 1312 },
          { id: 18, type: SINGLE, group: 1312 }
        ];

        groups = {
          values: [
            { value: 1,    parent: null, name: 'g1'   },
            { value: 11,   parent: 1,    name: 'g11'  },
            { value: 12,   parent: 1,    name: 'g12'  },
            { value: 13,   parent: 1,    name: 'g13'  },
            { value: 111,  parent: 11,   name: 'g111' },
            { value: 112,  parent: 11,   name: 'g112' },
            { value: 131,  parent: 13,   name: 'g131' },
            { value: 132,  parent: 13,   name: 'g132' },
            { value: 1311, parent: 131,  name: 'g1311'},
            { value: 1312, parent: 131,  name: 'g1312'},
            { value: 1313, parent: 131,  name: 'g1313'}
        ]};
      };

      beforeEach( function() {
        setData();
        priv.prepareDataStructures(nodes, null, groups, null);
      });

      it('calculate_group_cardinality() for top level group', function() {
        var cardinality = priv.calculateGroupCardinality(groups.values[0]);
        expect( cardinality ).toEqual(18);
      });

      it('calculate_group_cardinality() for group with no childern', function() {
        var cardinality = priv.calculateGroupCardinality(groups.values[10]);
        expect( cardinality ).toEqual(0);
      });

      it('calculate_group_cardinality() for group with no child groups', function() {
        var cardinality = priv.calculateGroupCardinality(groups.values[2]);
        expect( cardinality ).toEqual(2);
      });

      it('calculate_group_cardinality() for mid level group', function() {
        var cardinality = priv.calculateGroupCardinality(groups.values[3]);
        expect( cardinality ).toEqual(9);
      });

      it('calculateAllGroupsCardinality', function() {
        var groups_hash = priv.calculateAllGroupsCardinality();
        expect( groups_hash['G-1'].cardinality ).toEqual(18);
        expect( groups_hash['G-12'].cardinality ).toEqual(2);
        expect( groups_hash['G-13'].cardinality ).toEqual(9);
        expect( groups_hash['G-1313'].cardinality ).toEqual(0);
      });
    });
  });

  describe('Weight calculations', function() {
    var nodes  = null,
        groups = null;

    var setData = function() {
      nodes = [
        { id: 1, type:  SINGLE, group: 1    },
        { id: 2, type:  SINGLE, group: 11   },
        { id: 3, type:  SINGLE, group: 11   },
        { id: 4, type:  SINGLE, group: 111  },
        { id: 5, type:  SINGLE, group: 111  },
        { id: 6, type:  SINGLE, group: 112  },
        { id: 7, type:  SINGLE, group: 112  },
        { id: 8, type:  SINGLE, group: 12   },
        { id: 9, type:  SINGLE, group: 12   },
        { id: 10, type: SINGLE, group: 13   },
        { id: 11, type: SINGLE, group: 13   },
        { id: 12, type: SINGLE, group: 131  },
        { id: 13, type: SINGLE, group: 132  },
        { id: 14, type: SINGLE, group: 132  },
        { id: 15, type: SINGLE, group: 1311 },
        { id: 16, type: SINGLE, group: 1311 },
        { id: 17, type: SINGLE, group: 1312 },
        { id: 18, type: SINGLE, group: 1312 }
      ];

    /************************************************
                 G1
               / | \
              /  |  \ 
            G11 G12  G13
           / \       /  \
          /   \     /    \
       G111  G112  G131  G132
                   /  \
                  /    \
               G1311  G1312
    *************************************************/
      groups = {
        values: [
          { value: 1,    parent: null, name: 'g1'   ,cardinality: 18},
          { value: 11,   parent: 1,    name: 'g11'  ,cardinality: 6},
          { value: 12,   parent: 1,    name: 'g12'  ,cardinality: 2},
          { value: 13,   parent: 1,    name: 'g13'  ,cardinality: 9},
          { value: 111,  parent: 11,   name: 'g111' ,cardinality: 2},
          { value: 112,  parent: 11,   name: 'g112' ,cardinality: 2},
          { value: 131,  parent: 13,   name: 'g131' ,cardinality: 5},
          { value: 132,  parent: 13,   name: 'g132' ,cardinality: 2},
          { value: 1311, parent: 131,  name: 'g1311',cardinality: 2},
          { value: 1312, parent: 131,  name: 'g1312',cardinality: 2}
      ]};
    };

    beforeEach( function() {
      priv = service.priv;
      setData();
    });

   it('3 links between 2nd tier groups with weights 1 and 2', function() {
      var links = [
        {from_id: 17, from_type: SINGLE, to_id: 6, to_type: SINGLE, weight: 1},
        {from_id: 16, from_type: SINGLE, to_id: 3, to_type: SINGLE, weight: 1},
        {from_id: 8,  from_type: SINGLE, to_id: 3, to_type: SINGLE, weight: 6},
      ];
      service.collapseBranchByGroupValue(nodes, links, EMAILS, groups, 1);
      service.ungroupComboOnceById(nodes, 100001, links, EMAILS);
      expect( links.length ).toEqual(5);

      var combolink1 = _.find(links, function(l) {
        return l.from_id === 100013 && l.to_id === 100011;
      });
      expect( combolink1.weight ).toEqual(1);
      expect( combolink1.inner_links.length ).toEqual(2);

      var combolink2 = _.find(links, function(l) {
        return l.from_id === 100012 && l.to_id === 100011;
      });
      expect( combolink2.weight ).toEqual(6);
      expect( combolink2.inner_links.length ).toEqual(1);
    });

   it('with one initial link (single to single) in the graph', function() {
      var links = [
        {from_id: 18,  from_type: SINGLE, to_id: 3, to_type: SINGLE, weight: 1},
      ];
      service.collapseBranchByGroupValue(nodes, links, EMAILS, groups, 13);
      expect(links).toContain({from_id: 100013, from_type: 'combo', to_id: 3, to_type: 'single', way_arr: false, weight: 1, inner_links: ['L-18-3']});
    });

   it('with more initial links between singles in several groups', function () {
      var links = [
        {from_id: 18,  from_type: SINGLE, to_id: 17, to_type: SINGLE, weight: 1},
        {from_id: 18,  from_type: SINGLE, to_id: 8, to_type: SINGLE, weight: 1},
        {from_id: 8 ,  from_type: SINGLE, to_id: 17, to_type: SINGLE, weight: 1},
        {from_id: 14,  from_type: SINGLE, to_id: 2, to_type: SINGLE, weight: 1},
      ];
      service.collapseBranchByGroupValue(nodes, links, 1, groups, 13);
      expect( links.length ).toEqual(7);
    });

   it('with more initial links between singles in several groups - collapse other side', function () {
      var links = [
        {from_id: 18,  from_type: SINGLE, to_id: 17, to_type: SINGLE, weight: 1},
        {from_id: 18,  from_type: SINGLE, to_id: 8, to_type: SINGLE, weight: 2},
        {from_id: 8 ,  from_type: SINGLE, to_id: 17, to_type: SINGLE, weight: 3},
        {from_id: 14,  from_type: SINGLE, to_id: 2, to_type: SINGLE, weight: 1},
      ];

      service.collapseBranchByGroupValue(nodes, links, EMAILS, groups, 12);
      expect( links.length ).toEqual(6);
      expect(links).toContain({from_id: 18, from_type: 'single', to_id: 100012, to_type: 'combo', way_arr: false, weight: 2, inner_links: ['L-18-8']});
      expect(links).toContain({from_id: 100012, from_type: 'combo', to_id: 17, to_type: 'single', way_arr: false, weight: 3, inner_links: ['L-8-17']});
    });

   it('with pre-existing single to combo link', function () {
      nodes.push({id: 100012, type: 'combo', combo_type: 'single', image_url: undefined, group_type: 'g12', rate: 0, color: undefined, display: true, name: 'g12', containing_group_ref: 'G-1', combo_group_ref: 'G-12', to_links: [], from_links: [], sons_count: 2, contained_nodes_refs: []});

      var links = [
        {from_id: 18,  from_type: SINGLE, to_id: 17, to_type: SINGLE, weight: 7},
        {from_id: 18,  from_type: SINGLE, to_id: 8, to_type: SINGLE, weight: 7},
        {from_id: 18, from_type: 'single', to_id: 100012, to_type: 'combo', way_arr: false, weight: 7, inner_links: ['L-18-8']}
      ];

      service.collapseBranchByGroupValue(nodes, links, 1, groups, 131);
      expect( links.length ).toEqual(4);
    });

   it('with several initial links between groups', function () {
      nodes.push({id: 100012, type: 'combo', combo_type: 'single', image_url: undefined, group_type: 'g12', rate: 0, color: undefined, display: true, name: 'g12', containing_group_ref: 'G-1', combo_group_ref: 'G-12', to_links: [], from_links: [], sons_count: 2, contained_nodes_refs: []});
      nodes.push({id: 100131, type: 'combo', combo_type: 'single', image_url: undefined, group_type: 'g131', rate: 0, color: undefined, display: true, name: 'g131', containing_group_ref: 'G-13', combo_group_ref: 'G-131', to_links: [], from_links: [], sons_count: 5, contained_nodes_refs: []});

      var links = [
        {from_id: 18,     from_type: SINGLE, to_id: 17,    to_type: SINGLE, weight: 3},
        {from_id: 18,     from_type: SINGLE, to_id: 8,     to_type: SINGLE, weight: 3},
        {from_id: 18,     from_type: SINGLE, to_id: 100012,to_type: COMBO, way_arr: false, weight: 3, inner_links: ['L-18-8']},
        {from_id: 100131, from_type: COMBO, to_id: 100012, to_type: COMBO, way_arr: false, weight: 3, inner_links: ['L-18-8', 'L-18-100012']}
      ];

      service.collapseBranchByGroupValue(nodes, links, EMAILS, groups, 13);
      expect( links.length ).toEqual(5);
      var combolink1 = _.find(links, function(l) {
        return l.from_id === 100013 && l.to_id === 100012;
      });
      expect( combolink1.weight ).toEqual(3);
    });

   it('should work with a bunch of non-binary links', function() {
      var links = [
        {from_id: 18, from_type: SINGLE, to_id: 17, to_type: SINGLE, weight: 1},
        {from_id: 18, from_type: SINGLE, to_id: 8,  to_type: SINGLE, weight: 1},
        {from_id: 8,  from_type: SINGLE, to_id: 18, to_type: SINGLE, weight: 1},
        {from_id: 18, from_type: SINGLE, to_id: 5,  to_type: SINGLE, weight: 1},
        {from_id: 17, from_type: SINGLE, to_id: 4,  to_type: SINGLE, weight: 1},
        {from_id: 4,  from_type: SINGLE, to_id: 17, to_type: SINGLE, weight: 1},
        {from_id: 12, from_type: SINGLE, to_id: 4,  to_type: SINGLE, weight: 6},
        {from_id: 12, from_type: SINGLE, to_id: 3,  to_type: SINGLE, weight: 1},
        {from_id: 3,  from_type: SINGLE, to_id: 12, to_type: SINGLE, weight: 1},
        {from_id: 10, from_type: SINGLE, to_id: 5,  to_type: SINGLE, weight: 1}
      ];
      service.collapseBranchByGroupValue(nodes, links, EMAILS, groups, 1);
      service.ungroupComboOnceById(nodes, 100001, links, EMAILS);
      var link = _.find(links, function(l) {
        return (l.to_id === 100011 && l.from_id === 100013);
      });
      expect(link.weight).toEqual(2);
    });

   it('should work with a bunch of binary links', function() {
      var links = [
        {from_id: 18, from_type: SINGLE, to_id: 17, to_type: SINGLE, weight: 1},
        {from_id: 18, from_type: SINGLE, to_id: 8,  to_type: SINGLE, weight: 1},
        {from_id: 8,  from_type: SINGLE, to_id: 18, to_type: SINGLE, weight: 1},
        {from_id: 18, from_type: SINGLE, to_id: 5,  to_type: SINGLE, weight: 1},
        {from_id: 17, from_type: SINGLE, to_id: 4,  to_type: SINGLE, weight: 1},
        {from_id: 4,  from_type: SINGLE, to_id: 17, to_type: SINGLE, weight: 1},
        {from_id: 12, from_type: SINGLE, to_id: 4,  to_type: SINGLE, weight: 1},
        {from_id: 12, from_type: SINGLE, to_id: 3,  to_type: SINGLE, weight: 1},
        {from_id: 3,  from_type: SINGLE, to_id: 12, to_type: SINGLE, weight: 1},
        {from_id: 10, from_type: SINGLE, to_id: 5,  to_type: SINGLE, weight: 1}
      ];
      service.collapseBranchByGroupValue(nodes, links, 1, groups, 1);
      service.ungroupComboOnceById(nodes, 100001, links, 1);

      var link = _.find(links, function(l) {
        return (l.from_id === 100011 && l.to_id === 100013);
      });
      expect(link.weight).toEqual(1);
    });

   it ('should have a big binary link', function() {
      var links = [
        {from_id: 15,  from_type: SINGLE, to_id: 17, to_type: SINGLE, weight: 1},
        {from_id: 15,  from_type: SINGLE, to_id: 18, to_type: SINGLE, weight: 1},
        {from_id: 15,  from_type: SINGLE, to_id: 17, to_type: SINGLE, weight: 1}
      ];
      service.collapseBranchByGroupValue(nodes, links, 1, groups, 1311);
      service.collapseBranchByGroupValue(nodes, links, 1, groups, 1312);

      var link = _.find(links, function(l) {
        return (l.from_id === 101311 && l.to_id === 101312);
      });
      expect(link.weight).toEqual(4);
    });
  });

  describe('grouping with flat groups (age, rank, etc ..)', function() {
    var nodes  = null,
        groups = null;

    var setData = function() {
      nodes = [
        { id: 1, type:  SINGLE, group: 'Root'},
        { id: 2, type:  SINGLE, group: 'A'   },
        { id: 3, type:  SINGLE, group: 'B'   },
      ];

      groups = {
        values: ['Root', 'A', 'B']
      };
    };

    beforeEach( function() {
      priv = service.priv;
      setData();
    });

   it('Basic combine followed by uncobmine test with one link direction A to B', function() {
      var links = [
        {from_id: 2, from_type: SINGLE, to_id: 3, to_type: SINGLE, weight: 1},
      ];
      ///////////// Combine
      service.collapseBranchByGroupValue(nodes, links, EMAILS, groups, 'A');
      expect(nodes.length).toEqual(3);
      var node = _.find(nodes, {id: '100000A'});
      expect( node.type ).toEqual(COMBO);
      expect(links.length).toEqual(2);

      ///////////// Uncombine
      service.ungroupComboOnceById(nodes, '100000A', links, EMAILS);
      node = null;
      node = _.find(nodes, {id: '100000A'});
      expect( node ).not.toBeDefined();
      node = _.find(nodes, {id: 2});
      expect( node ).toBeDefined();
    });

   it('group all in flat groups', function() {
      nodes = [
        { id: 1, type:  SINGLE, group: 'A'},
        { id: 2, type:  SINGLE, group: 'A'},
        { id: 3, type:  SINGLE, group: 'B'},
        { id: 4, type:  SINGLE, group: 'B'},
        { id: 5, type:  SINGLE, group: 'C'}
      ];
      groups = {
        values: ['A', 'B', 'C']
      };
      var links = [
        {from_id: 1, from_type: SINGLE, to_id: 2, to_type: SINGLE, weight: 1},
        {from_id: 1, from_type: SINGLE, to_id: 3, to_type: SINGLE, weight: 1},
        {from_id: 2, from_type: SINGLE, to_id: 4, to_type: SINGLE, weight: 1},
        {from_id: 3, from_type: SINGLE, to_id: 2, to_type: SINGLE, weight: 1},
        {from_id: 1, from_type: SINGLE, to_id: 5, to_type: SINGLE, weight: 1},
        {from_id: 5, from_type: SINGLE, to_id: 4, to_type: SINGLE, weight: 1},
      ];
      service.collapseAllBranchsByGroupValue(nodes, links, 1, groups);
      expect(nodes.length).toEqual(3);
    });

   it('group all of flat groups with size zero should not be displayed', function() {
      nodes = [
        { id: 1, type:  SINGLE, group: 'A'},
        { id: 2, type:  SINGLE, group: 'A'},
        { id: 3, type:  SINGLE, group: 'B'}
      ];
      groups = { values: ['A', 'B', 'C', 'D'] };
      var links = [];

      service.collapseAllBranchsByGroupValue(nodes, links, 1, groups);
      expect( nodes.length ).toEqual(2);
      var combo = _.find(nodes, {id: '100000A'});
      expect( combo ).toBeDefined();
      combo = _.find(nodes, {id: '100000D'});
      expect( combo ).not.toBeDefined();
    });
  });

  describe('External entities', function() {
    var nodes  = null,
        groups = null,
        links  = null;

    var setData = function() {
      nodes = [
        { id: 1, type:  SINGLE, group: 1    },
        { id: 2, type:  SINGLE, group: 11   },
        { id: 3, type:  SINGLE, group: 11   },
        { id: 100,
          type: OVERLAY_ENTITY,
          name:"racheli.weiss@poalim.co.il",
          overlay_entity_group_id:"3682",
          overlay_entity_group_name:"poalim.co.il",
          overlay_entity_type_id:"1",
          overlay_entity_type_name:"external_domains",
          rate:"1"
        }
      ];

      groups = {
        values: [
          { value: 1,    parent: null, name: 'g1' },
          { value: 11,   parent: 1,    name: 'g11'},
          { value: 12,   parent: 1,    name: 'g12'}
      ]};

      links = [
        {from_id: 1, from_type: SINGLE, to_id: 2,   to_type: SINGLE, weight: 1},
        {from_id: 2, from_type: SINGLE, to_id: 100, to_type: OVERLAY_ENTITY, weight: 1},
      ];
    };

    beforeEach( function() {
      priv = service.priv;
      setData();
    });

   it('group single to single with an overlay entity which is not involved', function() {
      service.collapseBranchByGroupValue(nodes, links, EMAILS, groups, 1);
      expect( links.length ).toEqual(3);
    });

   it('group a regular node connected to an overlay entity', function() {
      service.collapseBranchByGroupValue(nodes, links, EMAILS, groups, 11);
      expect( links.length ).toEqual(4);
      var link = _.find(links, {from_id: 100011, to_id: 100});
      expect(link).toBeDefined();
    });

   it('group an overlay node connected to a single node', function() {
      links.push({from_id: 100, from_type: OVERLAY_ENTITY, to_id: 2, to_type: SINGLE, weight: 1});
      service.collapseBranchByGroupValue(nodes, links, EMAILS, groups, 11);
      expect( links.length ).toEqual(6);

      var single_to_combo = _.find(links, {from_id: 1, to_id: 100011});
      expect( single_to_combo ).toBeDefined();

      var overlay_to_combo = _.find(links, {from_id: 100, to_id: 100011});
      expect( overlay_to_combo ).toBeDefined();

      var combo_to_overlay = _.find(links, {from_id: 100011, to_id: 100});
      expect( combo_to_overlay ).toBeDefined();
    });

   it('group an overlay node connected to a combo', function() {
      service.collapseBranchByGroupValue(nodes, links, EMAILS, groups, 11);
      service.collapseBranchByGroupValue(nodes, links, EMAILS, groups, 1);
      expect( links.length ).toEqual(5);

      var single_to_combo = _.find(links, {from_id: 1, to_id: 100011});
      expect( single_to_combo ).toBeDefined();

      var combo_to_overlay = _.find(links, {from_id: 100011, to_id: 100});
      expect( combo_to_overlay ).toBeDefined();

      var higher_combo_to_overlay = _.find(links, {from_id: 100001, to_id: 100});
      expect( higher_combo_to_overlay ).toBeDefined();
    });

   it('group all with overlay - color by structure', function() {
      service.collapseAllByGroupValue(nodes, links, EMAILS, groups, 1);

      var combo = _.find(nodes, {id: 100001});
      expect( combo ).toBeDefined();
      expect( combo.display ).toEqual(true);

      var overlay_combo = _.find(nodes, {id: '100000poalim.co.il'});
      expect( overlay_combo ).toBeDefined();
      expect( overlay_combo.display ).toEqual(true);

      var combo_to_combo = _.find(links, {from_id: 100001, to_id: '100000poalim.co.il'});
      expect( combo_to_combo ).toBeDefined();
      expect(links.length).toEqual(3);
    });

   it('group all with overlay - color by gender', function() {
      groups = {values: ['something', 'else']};
      nodes = [
        { id: 1, type:  SINGLE, group: 'something'    },
        { id: 2, type:  SINGLE, group: 'else'   },
        { id: 3, type:  SINGLE, group: 'else'   },
        { id: 100,
          type: OVERLAY_ENTITY,
          name:"rawe@poalim.co.il",
          overlay_entity_group_id:"3682",
          overlay_entity_group_name:"poalim.co.il",
          overlay_entity_type_id:"1",
          overlay_entity_type_name:"external_domains",
          rate:"1"
        }
      ];

      service.collapseAllBranchsByGroupValue(nodes, links, 1, groups, 1);

      expect( nodes.length ).toEqual(3);
      expect( links.length ).toEqual(6);
      var signle_combo_to_overlay_combo = _.find(links, {from_id: '100000else', to_id: '100000poalim.co.il'});
      expect( signle_combo_to_overlay_combo ).toBeDefined();
    });

   it('group an overlay node into a combo', function() {
      service.collapseBranchByGroupValue(nodes, links, EMAILS, groups, 'poalim.co.il');
      expect( nodes.length ).toEqual(4);
      expect( links.length ).toEqual(3);
      var single_to_overlay_combo = _.find(links, {from_id: 2 , to_id: '100000poalim.co.il'});
      expect( single_to_overlay_combo ).toBeDefined();

    });

   it('ungroup an overlay combo', function() {
      service.collapseBranchByGroupValue(nodes, links, EMAILS, groups, 'poalim.co.il');
      var overlay_combo = _.find( nodes, {id: '100000poalim.co.il'});
      expect( overlay_combo ).toBeDefined();
      service.ungroupComboOnceById(nodes, '100000poalim.co.il', links, 1);
      overlay_combo = _.find( nodes, {id: '100000poalim.co.il'});
      expect( overlay_combo ).not.toBeDefined();
    });

   it('ungroup a combo linked to an overlay', function() {
      service.collapseBranchByGroupValue(nodes, links, EMAILS, groups, 1);
      service.ungroupComboOnceById(nodes, 100001, links, 1);

      expect( nodes.length ).toEqual(3);

      var overlay_node = _.find( nodes, {id: 100});
      expect( overlay_node ).toBeDefined();

      var single_node = _.find( nodes, {id: 1});
      expect( single_node ).toBeDefined();

      var regular_combo = _.find( nodes, {id: 100011});
      expect( regular_combo ).toBeDefined();
    });

   it('Group all then ungoup overlay combo', function() {
      service.collapseAllByGroupValue(nodes, links, EMAILS, groups, 1);
      service.ungroupComboOnceById(nodes, '100000poalim.co.il', links, EMAILS);

      expect( links.length ).toEqual(4);
      expect( nodes.length ).toEqual(2);
      var combo_to_overlay = _.find(links, {from_id: 100001, to_id: 100});
      expect( combo_to_overlay ).toBeDefined();
      expect( combo_to_overlay.weight ).toEqual(1);
      expect( combo_to_overlay.to_type ).toEqual(OVERLAY_ENTITY);
    });
  });

  describe('Link utilities', function() {
    var nodes = [ { id: 1, type:  SINGLE, group: 1}, { id: 2, type:  SINGLE, group: 11} ];
    var groups = { values: [{value: 1, parent: null, name: 'g1' }, {value: 11, parent: 1, name: 'g11'} ]};
    var links = [{from_id: 1, from_type: SINGLE, to_id: 2,   to_type: SINGLE, weight: 1} ];

   it('should return node of origin', function() {
      priv.prepareDataStructures(nodes, links, groups, null);
      var res = service.getLinkOriginNode('L-1-2');
      expect( res ).toBeDefined();
      expect( res.id ).toEqual(1);
    });

   it('should return node of destination', function() {
      priv.prepareDataStructures(nodes, links, groups, null);
      var res = service.getLinkDestinationNode('L-1-2');
      expect( res ).toBeDefined();
      expect( res.id ).toEqual(2);
    });
  });

  describe('calculateComboRate() and calculateComboStandardDeviation()', function() {
    var nodes = null,
        groups = null;

    var setData = function() {
      nodes = [
        { id: 1, type:  SINGLE, group: 1 , rate: 1},
        { id: 2, type:  SINGLE, group: 11, rate: 1},
        { id: 3, type:  SINGLE, group: 11, rate: 2},
        { id: 4, type:  SINGLE, group: 11, rate: 1},
      ];

      groups = {
        values: [
          { value: 1,    parent: null, name: 'g1'   },
          { value: 11,   parent: 1,    name: 'g11'  },
          { value: 12,   parent: 1,    name: 'g12'  },
      ]};
    };

    beforeEach( function() {
      setData();
      priv.prepareDataStructures(nodes, null, groups, null);
    });

   it('vanila case for calculateComboRate', function() {
      service.collapseBranchByGroupValue(nodes, [], EMAILS, groups, 11);
      var rate = service.calculateComboRate( nodes[1] );
      expect( rate ).toEqual(0.133);
    });

   it('empty combo', function() {
      service.collapseBranchByGroupValue(nodes, [], EMAILS, groups, 12);
      var rate = service.calculateComboRate( nodes[1] );
      expect( rate ).toEqual(0);
    });

   it('vanila case for calculateComboStandardDeviation', function() {
      service.collapseBranchByGroupValue(nodes, [], EMAILS, groups, 11);
      var std = service.calculateComboStandardDeviation( nodes[1] );
      expect( std ).toEqual(0.13);
    });
  });
 });
