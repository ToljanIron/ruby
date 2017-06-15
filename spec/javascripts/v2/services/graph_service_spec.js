/*globals describe, it, xit, expect, beforeEach, _,  angular, mock, module, inject, unused */

describe('graphService', function () {
  'use strict';

  beforeEach(angular.mock.module('workships.services'));
  beforeEach(angular.mock.module('StateRouter'));

  var service, dataModel, stateService;

  beforeEach(inject(function (graphService, dataModelService, initializeAppState, StateService, tabService) {
    service = graphService;
    dataModel = dataModelService;
    stateService = StateService;
    tabService.init();
    tabService.current_tab = 'Explore';
    stateService.set({name:  'Explore' + '_selected', value: 1});
    initializeAppState.initialize();
  }));


  it('should be defined', function () {
    expect(service).toBeDefined();
    expect(service.group_by_id).toBeDefined();
    expect(service.layout_name).toBeDefined();
    expect(service.event_handlers).toBeDefined();
    expect(service.setNodes).toBeDefined();
    expect(service.setLinks).toBeDefined();
    expect(service.setData).toBeDefined();
    expect(service.setGroupBy).toBeDefined();
    expect(service.setEventHandler).toBeDefined();
    expect(service.groupAll).toBeDefined();
    expect(service.ungroupAll).toBeDefined();
    expect(service.setSearch).toBeDefined();
    expect(service.setFilterByNodesIds).toBeDefined();
    expect(service.getNodes).toBeDefined();
    expect(service.getLinks).toBeDefined();
    expect(service.getLayout).toBeDefined();
    expect(service.getSearch).toBeDefined();
    expect(service.getEverythingInsideAllCombos()).toBeDefined();
    expect(service.getEventHandlerOnClick).toBeDefined();
    expect(service.getEventHandlerOnDblClick).toBeDefined();
    expect(service.getEventHandlerOnRightClick).toBeDefined();
  });

  describe('updateLinksWeight()', function () {
    xit('should change the links from combo to node to average ', function () {
      service.mock();
      var combo_id = 'male';
      service.updateLinksWeight(combo_id);
      var links = service.getLinks();
      expect(_.find(links, { from_id: combo_id}).weight).toBe(4);
      expect(links.length).toBe(1);
    });
  });

  describe('getEverythingInsideAllCombos()', function () {
    it('should return all singles inside all combos on all levels', function () {
      service.mockCombinedNodes();
      var expected = [{id: 1, type: 'single'},
        {id: 2, type: 'single'},
        {id: 2, type: 'combo'},
        {id: 3, type: 'combo'},
        {id: 3, type: 'single'},
        {id: 4, type: 'single'},
        {id: 5, type: 'single'},
        {id: 6, type: 'single'}];
      var result = _.map(service.getEverythingInsideAllCombos(), function (node) {
        return { id: node.id, type: node.type };
      });
      expect(result).toEqual(expected);
    });

    it('should not return open singles', function () {
      service.mockCombinedNodes();
      expect(_.any(service.getEverythingInsideAllCombos(), _.matches({ id: 7, type: 'single' }))).toBeFalsy();
    });

    it('should return [] if no combos', function () {
      service.mockNoCombos();
      expect(service.getEverythingInsideAllCombos()).toEqual([]);
    });
  });

  describe('setSearch()', function () {
    beforeEach(function () {
      service.mockCombinedNodes();
    });

    it('should set search to a given single if it is open', function () {
      service.setSearch({ id: 7, type: 'single' });
      expect(service.getSearch()).toEqual({ id: 7, type: 'single' });
    });

    it('should set search to combo containing a given single if it is not open', function () {
      service.setSearch({ id: 3, type: 'single' });
      expect(service.getSearch()).toEqual({ id: 1, type: 'combo' });
    });

    it('should set search to a given combo if it is open', function () {
      service.setSearch({ id: 4, type: 'combo' });
      expect(service.getSearch()).toEqual({ id: 4, type: 'combo' });
    });

    it('should set search to combo containing a given combo if it is not open', function () {
      service.setSearch({ id: 2, type: 'combo' });
      expect(service.getSearch()).toEqual({ id: 1, type: 'combo' });
    });
  });

  describe('ungroupAll()', function () {
    describe('simple case', function () {
      it('should uncombine all single nodes when all grouped', function () {
        var expected = [{id: 7, type: 'single'},
          {id: 1, type: 'single'},
          {id: 2, type: 'single'},
          {id: 3, type: 'single'},
          {id: 4, type: 'single'},
          {id: 5, type: 'single'},
          {id: 6, type: 'single'}];
        service.mockCombinedNodes();
        service.mockAllNodesAndLinks();
        service.ungroupAll();
        expect(_.map(service.getNodes(), function (node) {
          return { id: node.id, type: node.type };
        })).toEqual(expected);
      });

      it('should do nothing when no combo nodes', function () {
        service.mockNoCombos();
        service.mockAllNodesAndLinks();
        var expected = _.cloneDeep(service.getNodes());
        service.ungroupAll();
        expect(_.map(service.getNodes(), function (node) {
          return { id: node.id, type: node.type };
        })).toEqual(expected);
      });
    });

    // describe('with isolated node', function () {
    //   var chosen;

    //   it('should isolate same node if it is present after group all', function () {
    //     service.mockHalfCombinedWithIsolated();
    //     service.setIsolated(1, 'single');
    //     chosen = service.getIsolated();
    //     service.ungroupAll();
    //     expect(service.getIsolated()).toEqual(chosen);
    //   });

    //   it('should unisolate isolated node if it is not present after group all', function () {
    //     service.mockHalfCombinedWithIsolated();
    //     service.ungroupAll();
    //     expect(service.getIsolated()).toEqual({});
    //   });
    // });
  });

  describe('groupAll()', function () {
    var result;

    describe('simple test', function () {
      beforeEach(function () {
        dataModel.mock();
        service.mockGroupByStructure();
        service.mockAllNodesAndLinks();
        service.groupAll();
        result = service.getNodes();
      });

      it('should leave one combo node if group by is recursive', function () {
        expect(result.length).toEqual(1);
        expect(result[0].type).toEqual('combo');
        expect(result[0].id).toEqual(1);
      });

      it('should combine recursively if group by is recursive', function () {
        expect(result[0].combos[0].id).toEqual(2);
        expect(result[0].singles[0].id).toEqual(1);
        expect(result[0].combos[0].combos.length).toEqual(2);
        expect(result[0].combos[0].combos[0].id).toEqual(3);
        expect(result[0].combos[0].combos[1].id).toEqual(4);
        expect(result[0].combos[0].singles[0].id).toEqual(2);
        expect(result[0].combos[0].combos[0].singles[0].id).toEqual(3);
        expect(result[0].combos[0].combos[1].singles[0].id).toEqual(4);
      });
    });

    // describe('with isolated node', function () {
    //   var chosen;

    //   it('should isolate same node if it is present after group all', function () {
    //     service.mockHalfCombinedWithIsolated();
    //     chosen = service.getIsolated();
    //     service.groupAll();
    //     expect(service.getIsolated()).toEqual(chosen);
    //   });

    //   it('should unisolate isolated node if it is not present after group all', function () {
    //     service.mockHalfCombinedWithIsolated();
    //     service.setIsolated(1, 'single');
    //     service.groupAll();
    //     expect(service.getIsolated()).toEqual({});
    //   });
    // });
  });

  describe('calculate graph witn 1-0 network', function () {
    var links;
    var node_to_click = 48;
    var node_to_click_un_group = 'combo1';

    beforeEach(function () {
      service.mockSingleAndComboToCalculateEdgeWeight();
      links = service.getLinks();
      dataModel.mock();
      service.mockAllNodesAndLinks();
      dataModel.addGroup('combo1');
    });
    it('should combine 2 ndoes and create a 2 edge with value 6 and 3 with only one direction', function () {
      service.getEventHandlerOnDblClick(node_to_click, 'single');
      expect(_.find(service.getLinks(), { from_id: 47, from_type: 'single', to_id: 'combo1', to_type: 'combo'}).weight).toEqual(3);
      expect(_.find(service.getLinks(), { from_id: 'combo1', from_type: 'combo', to_id: 47, to_type: 'single'}).weight).toEqual(6);
    });
    it('should un-group the previews group and redo group and get the same values', function () {
      service.getEventHandlerOnDblClick(node_to_click, 'single');
      service.getEventHandlerOnDblClick(node_to_click_un_group, 'combo');
      service.getEventHandlerOnDblClick(node_to_click, 'single');
      expect(_.find(service.getLinks(), { from_id: 47, from_type: 'single', to_id: 'combo1', to_type: 'combo'}).weight).toEqual(3);
      expect(_.find(service.getLinks(), { from_id: 'combo1', from_type: 'combo', to_id: 47, to_type: 'single'}).weight).toEqual(6);
      expect(links.length).toEqual(2);
    });
  });
  // mockSingleAndCombos

  describe('graphService.filterByEdgeSize with group', function () {
    var links_before_filter;
    beforeEach(function () {
      service.mockToFilterComboAndSingles();
      service.mockAllNodesAndLinks();
      links_before_filter = service.getLinks();
      dataModel.mock();
    });
    it('should leave everything when limits are from 1 to 6', function () {
      service.filterByEdgeSize({ from: 1, to: 6 });
      expect(service.getLinks()).toEqual(links_before_filter);
    });
    it('should leave only the links that are in range', function () {
      service.getEventHandlerOnDblClick(2, 'single');
      service.filterByEdgeSize({ from: 2, to: 5 });
      expect(_.pluck(service.getLinks(), 'weight')).toEqual([3, 3]);
    });
    it('should filter out the nodes that aren\'t connected to any link if not full range', function () {
      service.getEventHandlerOnDblClick(2, 'single');
      service.filterByEdgeSize({ from: 3, to: 4 });
      expect(_.pluck(service.getNodes(), 'id')).toEqual([1, 4, 5, 'combo2']);
    });
    it('should filter out the nodes and links after double click', function () {
      service.getEventHandlerOnDblClick(2, 'single');
      service.filterByEdgeSize({ from: 2, to: 5 });
      service.getEventHandlerOnDblClick(1, 'single');
      expect(_.pluck(service.getLinks(), 'weight')).toEqual([4.5]);
    });

    it('should filter out the nodes and links after un group', function () {
      service.getEventHandlerOnDblClick(2, 'single');
      service.filterByEdgeSize({ from: 2, to: 5 });
      service.getEventHandlerOnDblClick(1, 'single');
      dataModel.addGroup('combo1');
      service.getEventHandlerOnDblClick('combo1', 'combo');
      expect(_.pluck(service.getLinks(), 'weight')).toEqual([3, 3]);
      expect(_.pluck(service.getNodes(), 'id')).toEqual([4, 'combo2', 1, 5]);
    });
  });

  describe('graphService.filterByEdgeSize', function () {
    var links_before_filter;

    beforeEach(function () {
      service.mockLinksWithWeights();
      service.mockAllNodesAndLinks();
      links_before_filter = service.getLinks();
    });

    it('should leave everything when limits are from 1 to 6', function () {
      service.filterByEdgeSize({ from: 1, to: 6 });
      expect(service.getLinks()).toEqual(links_before_filter);
    });

    it('should leave only the links that are in range', function () {
      service.filterByEdgeSize({ from: 2, to: 5 });
      expect(_.pluck(service.getLinks(), 'weight')).toEqual([2, 3, 4, 5]);
    });

    it('should filter out the nodes that aren\'t connected to any link if not full range', function () {
      service.filterByEdgeSize({ from: 3, to: 4 });
      expect(_.pluck(service.getNodes(), 'id')).toEqual([1, 2, 3, 4, 5, 6, 7]);
    });
  });

  describe('big graph test2', function () {
    var links;
    var nodes;
    //var node_to_click = 1;
    var hash = { 1: 'single', 2: 'single', 4: 'combo', 5: 'combo' };

    beforeEach(function () {
      service.mockSingleAndCombosMore();
      service.mockAllNodesAndLinks();
      dataModel.mock();
    });

    it('should count singles for top level single1', function () {
      links = service.getLinksForTest();
      service.getEventHandlerOnDblClick(1, hash[1]);
      nodes = service.getNodes();
      links = service.getLinksForTest();
      expect(_.filter(nodes, {type: 'single'}).length).toEqual(0);
      expect(_.filter(nodes, {type: 'combo'}).length).toEqual(1);
      expect(links.length).toEqual(0);
    });

    it('should count singles for top level single2', function () {
      links = service.getLinksForTest();
      service.getEventHandlerOnDblClick(2, hash[2]);
      nodes = service.getNodes();
      links = service.getLinksForTest();
      expect(_.filter(nodes, {type: 'single'}).length).toEqual(1);
      expect(_.filter(nodes, {type: 'combo'}).length).toEqual(1);
      expect(service.getAllLinks().length).toEqual(8);
    });
    it('should count singles for top level combo1', function () {
      service.getEventHandlerOnDblClick(4, hash[4]);
      nodes = service.getNodes();
      links = service.getLinksForTest();
      expect(_.filter(nodes, {type: 'single'}).length).toEqual(3);
      expect(_.filter(nodes, {type: 'combo'}).length).toEqual(1);
      expect(service.getAllLinks().length).toEqual(8);
    });
    it('should count singles for top level combo2', function () {
      dataModel.addGroup(5);
      service.getEventHandlerOnDblClick(5, hash[5]);
      nodes = service.getNodes();
      links = service.getLinksForTest();
      expect(_.filter(nodes, {type: 'single'}).length).toEqual(3);
      expect(_.filter(nodes, {type: 'combo'}).length).toEqual(1);
      expect(service.getAllLinks().length).toEqual(8);
    });
  });

  describe('group when no attribute', function () {
    beforeEach(function () {
      service.mockNodesWithNoAttribute();
      service.mockAllNodesAndLinks();
      service.getEventHandlerOnDblClick(1, 'single');
    });

    it('should combine all nodes with no attribute', function () {
      expect(service.getNodes().length).toEqual(1);
      expect(service.getNodes()[0].type).toEqual('combo');
      expect(service.getNodes()[0].id).toEqual('Unknown');
    });
  });

  describe('setFilterByNodesIds', function () {
    var nodes, links, expectShown, expectHidden;

    expectShown = function (obj) {
      expect(obj.hide).toBeFalsy();
    };

    expectHidden = function (obj) {
      expect(obj.hide).toEqual(true);
    };

    describe('when graph consists just of single nodes', function () {
      beforeEach(function () {
        service.mockNoCombos();
        service.setFilterByNodesIds([1, 2]);
        nodes = service.getNodes();
        links = service.getLinks();
      });

      it('should hide all nodes except those that it received as arguments', function () {
        expectHidden(_.find(nodes, { id: 3 }));
        expectHidden(_.find(nodes, { id: 4 }));
        expectShown(_.find(nodes, { id: 1 }));
        expectShown(_.find(nodes, { id: 2 }));
      });

      it('should hide all edges that are connected to one hidden node', function () {
        expect(_.find(links, { from_id: 2, from_type: 'single', to_id: 3, to_type: 'single' }).hide).toEqual(true);
        expect(_.find(links, { from_id: 4, from_type: 'single', to_id: 1, to_type: 'single' }).hide).toEqual(true);
      });

      it('should hide all edges that are connected to hidden nodes from both ends', function () {
        expect(_.find(links, { from_id: 3, from_type: 'single', to_id: 4, to_type: 'single' }).hide).toEqual(true);
      });

      it('should show all edges that have both ends in arguments', function () {
        expectShown(_.find(links, { from_id: 1, from_type: 'single', to_id: 2, to_type: 'single' }));
      });
    });

    describe('when graph consists of single and combo nodes', function () {
      var singles, combos;
      beforeEach(function () {
        service.mockSinglesCombosAndLinks();
        service.setFilterByNodesIds([1, 3, 11]);
        nodes = service.getNodes();
        links = service.getLinks();
        singles = _.where(nodes, { type: 'single' });
        combos = _.where(nodes, { type: 'combo' });
      });

      it('should hide all single nodes except those that it received as arguments', function () {
        expectShown(_.find(singles, { id: 1 }));
        expectHidden(_.find(singles, { id: 2 }));
      });

      it('should hide all combo nodes that consist solely of hidden singles', function () {
        expectHidden(_.find(combos, { id: 5 }));
      });

      it('should show all combo nodes that have at least one single node inside that is present in arguments', function () {
        expectShown(_.find(combos, { id: 4 }));
      });

      it('should hide links between single and combo if single is hidden', function () {
        expectHidden(_.find(links, { from_id: 2, from_type: 'single', to_id: 4, to_type: 'combo' }));
      });

      it('should hide links between single and combo if combo is hidden', function () {
        expectHidden(_.find(links, { from_id: 1, from_type: 'single', to_id: 5, to_type: 'combo' }));
      });

      it('should hide links between single and combo if both are shown but link consists solely of single links that are connected to hidden singles in shown combo', function () {
        expectHidden(_.find(links, { from_id: 1, from_type: 'single', to_id: 4, to_type: 'combo' }));
      });

      it('should show links between single and combo if single is shown and one of the original links is connected to a shown single in combo', function () {
        expectShown(_.find(links, { from_id: 1, from_type: 'single', to_id: 10, to_type: 'combo' }));
      });
    });

    describe('when graph consists just of combo nodes', function () {
      var combos;

      describe(', one level hierarchy', function () {
        beforeEach(function () {
          service.mockNoSinglesOneLevel();
          service.setFilterByNodesIds([1, 2, 3]);
          nodes = service.getNodes();
          links = service.getLinks();
          combos = _.where(nodes, { type: 'combo' });
        });

        it('should hide all combo nodes that consist of singles that are not in the arguments', function () {
          expectHidden(_.find(combos, { id: 3 }));
          expectHidden(_.find(combos, { id: 4 }));
        });

        it('should show combo node that has one single nodes that is in the arguments', function () {
          expectShown(_.find(combos, { id: 2 }));
        });

        it('should show combo node that has all single nodes in the arguments', function () {
          expectShown(_.find(combos, { id: 1 }));
        });

        it('should hide link if one combo end is hidden', function () {
          expectHidden(_.find(links, { from_id: 2, from_type: 'combo', to_id: 3, to_type: 'combo' }));
        });

        it('should hide link if both combo ends are hidden', function () {
          expectHidden(_.find(links, { from_id: 3, from_type: 'combo', to_id: 4, to_type: 'combo' }));
        });

        it('should show link if one of its original single-to-single links is connected to two nodes that are in arguments', function () {
          expectShown(_.find(links, { from_id: 1, from_type: 'combo', to_id: 2, to_type: 'combo' }));
        });

        it('should hide link if all of its original single-to-single links are connected to hidden node at least from one end', function () {
          expectHidden(_.find(links, { from_id: 2, from_type: 'combo', to_id: 4, to_type: 'combo' }));
        });
      });

      describe(', multiple level hierarchy', function () {
        beforeEach(function () {
          service.mockNoSinglesMultipleLevel();
          service.setFilterByNodesIds([1, 2, 3, 4]);
          nodes = service.getNodes();
          links = service.getLinks();
          combos = _.where(nodes, { type: 'combo' });
        });

        it('should hide all combo nodes that consist of singles that are not in the arguments', function () {
          expectHidden(_.find(combos, { id: 6 }));
          expectHidden(_.find(combos, { id: 10 }));
        });

        it('should show combo node that has one single node that is in the arguments', function () {
          expectShown(_.find(combos, { id: 3 }));
        });

        it('should show combo node that has all single nodes in the arguments', function () {
          expectShown(_.find(combos, { id: 1 }));
        });

        it('should hide link if one combo end is hidden', function () {
          expectHidden(_.find(links, { from_id: 3, from_type: 'combo', to_id: 6, to_type: 'combo' }));
        });

        it('should hide link if both combo ends are hidden', function () {
          expectHidden(_.find(links, { from_id: 6, from_type: 'combo', to_id: 10, to_type: 'combo' }));
        });

        it('should show link if at least one of its original single-to-single links is connected to two nodes that are in arguments', function () {
          expectShown(_.find(links, { from_id: 1, from_type: 'combo', to_id: 3, to_type: 'combo' }));
        });

        it('should hide link if all of its original single-to-single links are connected to at least one hidden node', function () {
          expectHidden(_.find(links, { from_id: 3, from_type: 'combo', to_id: 10, to_type: 'combo' }));
        });
      });
    });
  });

  describe('graphService.neighbours', function () {
    var neighbours;

    it('should return only the node that is given if it is not connected to any other node', function () {
      service.setNodes([{ id: 1 }]);
      neighbours = service.neighbours(1, 'single');
      expect(neighbours.length).toEqual(1);
      expect(neighbours[0].id).toEqual(1);
      expect(neighbours[0].type).toEqual('single');
    });

    it('should return nodes connected to a given one by link', function () {
      service.setNodes([{ id: 1 }, { id: 2 }]);
      service.setLinks([{ from_emp_id: 1, to_emp_id: 2 }]);
      neighbours = service.neighbours(1, 'single');
      expect(neighbours.length).toEqual(2);
      expect(neighbours).toContain({ id: 1, type: 'single', hide: false });
      expect(neighbours).toContain({ id: 2, type: 'single', hide: false });
    });

    it('should not return nodes not connected to a given one by link', function () {
      service.setNodes([{ id: 1 }, { id: 2 }, { id: 3 }]);
      service.setLinks([{ from_emp_id: 1, to_emp_id: 2 }]);
      neighbours = _.map(service.neighbours(1, 'single'), function (n) {
        return { id: n.id, type: n.type };
      });
      expect(neighbours).not.toContain({ id: 3, type: 'single' });
    });
  });

  describe('graphService.allSingles', function () {
    var array;

    it('should return a given array if it consists only of singles', function () {
      array = [{ id: 1, type: 'single' },
               { id: 2, type: 'single' },
               { id: 3, type: 'single' }];
      expect(service.allSingles(array)).toEqual(array);
    });

    it('should return array of singles if given array of combos', function () {
      array = [{ id: 1, type: 'combo', singles: [{ id: 1, type: 'single' }, { id: 2, type: 'single' }] },
               { id: 2, type: 'combo', combos: [{ id: 3, type: 'combo', singles:
                  [{ id: 3, type: 'single' }] }] },
               { id: 4, type: 'combo', combos: [{ id: 5, type: 'combo', combos:
                  [{ id: 6, type: 'combo', singles:
                    [{ id: 4, type: 'single' }] }] }], singles: [{ id: 5, type: 'single' }] }];
      expect(service.allSingles(array)).toContain({ id: 1, type: 'single' });
      expect(service.allSingles(array)).toContain({ id: 2, type: 'single' });
      expect(service.allSingles(array)).toContain({ id: 3, type: 'single' });
      expect(service.allSingles(array)).toContain({ id: 4, type: 'single' });
      expect(service.allSingles(array)).toContain({ id: 5, type: 'single' });
    });
  });

  describe('setIsolated', function () {
    var isolated_group;

    describe('when all nodes are singles', function () {
      beforeEach(function () {
        service.mockNoCombos();
        service.setIsolated(1, 'single');
        isolated_group = service.getIsolatedGroup();
      });

      it('should set isolated to given node', function () {
        expect(service.getIsolated()).toEqual({ id: 1, type: 'single' });
      });

      it('should set isolated group on given node and all neighbours', function () {
        expect(isolated_group).toContain({ id: 1, type: 'single' });
        expect(isolated_group).toContain({ id: 2, type: 'single' });
        expect(isolated_group).toContain({ id: 4, type: 'single' });
      });
    });

    describe('when nodes are singles and combos', function () {
      beforeEach(function () {
        service.mockSinglesCombosAndLinks();
      });

      describe('when clicking on single', function () {
        beforeEach(function () {
          service.setIsolated(1, 'single');
          isolated_group = service.getIsolatedGroup();

        });

        it('should set isolated to a clicked node', function () {
          expect(service.getIsolated()).toEqual({ id: 1, type: 'single' });
        });

        it('should set isolated group to all singles in all neighbours of a clicked node', function () {
          expect(isolated_group.length).toEqual(6);
          expect(isolated_group).toContain({ id: 1, type: 'single' });
          expect(isolated_group).toContain({ id: 3, type: 'single' });
          expect(isolated_group).toContain({ id: 6, type: 'single' });
          expect(isolated_group).toContain({ id: 7, type: 'single' });
          expect(isolated_group).toContain({ id: 9, type: 'single' });
          expect(isolated_group).toContain({ id: 11, type: 'single' });
        });
      });

      describe('when clicking on combo', function () {
        beforeEach(function () {
          service.setIsolated(4, 'combo');
          isolated_group = service.getIsolatedGroup();
        });

        it('should set isolated to a clicked node', function () {
          expect(service.getIsolated()).toEqual({ id: 4, type: 'combo' });
        });

        it('should set isolated group to all singles of clicked combo and all singles of all neighbours', function () {
          expect(isolated_group.length).toEqual(4);
          expect(isolated_group).toContain({ id: 1, type: 'single' });
          expect(isolated_group).toContain({ id: 2, type: 'single' });
          expect(isolated_group).toContain({ id: 3, type: 'single' });
          expect(isolated_group).toContain({ id: 7, type: 'single' });
        });
      });
    });

  });

  describe('setLayout', function () {
    describe('advanced', function () {
      it('should run rh.startFR if no cached nodes', function () {
        service.mockSingleAndCombos();
        spyOn(rh, 'startFR').and.callFake(function (graph, unused) { unused(graph); });
        service.setLayout('advanced');
        expect(rh.startFR).toHaveBeenCalled();
      });
    });
  });

});