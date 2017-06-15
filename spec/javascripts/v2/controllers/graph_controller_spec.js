/*globals _, describe, it , inject, unused ,expect, beforeEach, angular, mock, module, $controller, document, window, mockController, spyOn */

describe('NewGraphCtrl', function () {
  'use strict';

  var controller, scope, graphService;
  beforeEach(angular.mock.module('StateRouter'));

  function mockFilters(get_filtered, get_filter_group_ids) {
    scope.selected = {
      filter: {
        getFiltered: function () {
          return get_filtered;
        },
        getFilterGroupIds: function () {
          return get_filter_group_ids;
        }
      }
    };
  }
  function mockNetworks(network_name, network_id, relation) {
    var original_relation = _.cloneDeep(relation);
    var new_network = {name: network_name, network_index: network_id, network_bundle: [network_id],
        relation: relation, original_relation: original_relation };
    scope.analyze_data.networks.push(new_network);
    return new_network;

  }
  function mockMetrics(metric_name, network_ids) {
    return { metric_name: metric_name, network_ids: network_ids };
  }

  beforeEach(function () {
    var mocked_controller = mockController('NewGraphCtrl');
    controller = mocked_controller.controller;
    scope = mocked_controller.scope;
  });

  it('should be defined', function () {
    expect(controller).toBeDefined();
    expect(scope.updateData).toBeDefined();
    expect(scope.setGroupBy).toBeDefined();
    expect(scope.setFilter).toBeDefined();
    expect(scope.metricsByNetwork).toBeDefined();
    expect(scope.toggleLayoutMenu).toBeDefined();
  });

  describe('setFilter', function () {
    beforeEach(inject(function ($injector) {
      graphService = $injector.get('graphService');
      scope.employees = [{ id: 1, gender: 'male', group_id: 1, friendship: 8 },
                         { id: 2, gender: 'female', group_id: 1, friendship: 10 },
                         { id: 3, gender: 'female', group_id: 2, friendship: 1}];
      scope.groups = [{ id: 1, name: 'Group1' }, { id: 2, name: 'Group2' }];
      controller.setEmployeesNumber = function (n) {
        return n;
      };
      controller.level_filters = ['friendship'];
      spyOn(graphService, 'setFilterByNodesIds');
    }));

    it('should filter by criteria', function () {
      mockFilters({ gender: ['female'] }, [1, 2]);
      scope.setFilter();
      expect(graphService.setFilterByNodesIds).toHaveBeenCalledWith([2, 3], 3);
    });

    it('should filter by level filter', function () {
      mockFilters({ friendship: [0, 9] }, [1, 2]);
      scope.setFilter();
      expect(graphService.setFilterByNodesIds).toHaveBeenCalledWith([1, 3], 3);
    });

    it('should filter by criteria and level filters', function () {
      mockFilters({ gender: ['female'], friendship: [0, 9] }, [1, 2]);
      scope.setFilter();
      expect(graphService.setFilterByNodesIds).toHaveBeenCalledWith([3], 3);
    });

    it('should filter by criteria, level and group filters', function () {
      mockFilters({ gender: ['female'], friendship: [1, 10] }, [1]);
      scope.setFilter();
      expect(graphService.setFilterByNodesIds).toHaveBeenCalledWith([2], 3);
    });

    it('should not filter when no criteria/level filters and group filter is empty', function () {
      mockFilters({}, []);
      scope.setFilter();
      expect(graphService.setFilterByNodesIds).toHaveBeenCalledWith([1, 2, 3], 3);
    });

    it('should not filter when no criteria/level filters and group filter includes all groups', function () {
      mockFilters({}, [1, 2]);
      scope.setFilter();
      expect(graphService.setFilterByNodesIds).toHaveBeenCalledWith([1, 2, 3], 3);
    });
  });

  describe('find_or_create_network', function () {
    var n1, item;
    beforeEach(function () {
      scope.analyze_data = { networks: [] };
      n1 = mockNetworks('one', 2, [{from_emp_id: 1, to_emp_id: 5, weight: 1}, {from_emp_id: 3, to_emp_id: 7, weight: 1}]);
      mockNetworks('two', 4, [{from_emp_id: 1, to_emp_id: 2, weight: 1}, {from_emp_id: 3, to_emp_id: 4, weight: 1}]);
    });
    it('should return the network one', function () {
      item = mockMetrics('metric_1', [2]);
      expect(scope.findOrCreateNetwork(item)).toEqual(n1);
      expect(scope.analyze_data.networks.length).toEqual(2);
    });
    it('should return a new network', function () {
      item = mockMetrics('metric_1', [2, 4]);
      scope.findOrCreateNetwork(item);
      expect(scope.analyze_data.networks.length).toEqual(3);
    });
    describe('calculate the new network', function () {
      it('should return the new network with 3 links beacuse 1 links is from Communication flow and less then 3', function () {
        mockNetworks('Communication Flow', 3, [{from_emp_id: 1, to_emp_id: 5, weight: 2}, {from_emp_id: 3, to_emp_id: 7, weight: 5}]);
        item = mockMetrics('metric_3', [3, 4]);
        scope.findOrCreateNetwork(item);
        expect(scope.analyze_data.networks.length).toEqual(4);
        expect(scope.analyze_data.networks[3].original_relation.length).toEqual(3);
      });
      it('should create only one time the new network', function () {
        mockNetworks('Communication Flow', 3, [{from_emp_id: 1, to_emp_id: 5, weight: 2}, {from_emp_id: 3, to_emp_id: 7, weight: 5}]);
        item = mockMetrics('metric_3', [3, 4]);
        scope.findOrCreateNetwork(item);
        item = mockMetrics('metric_4', [3, 4]);
        expect(scope.analyze_data.networks.length).toEqual(4);
      });
      it('should create in the network  a new link only one time if exsist in more then 1 network', function () {
        mockNetworks('Communication Flow', 3, [{from_emp_id: 1, to_emp_id: 5, weight: 2}, {from_emp_id: 1, to_emp_id: 2, weight: 5}]);
        item = mockMetrics('metric_3', [3, 4]);
        scope.findOrCreateNetwork(item);
        expect(scope.analyze_data.networks[3].original_relation.length).toEqual(2);
      });
      it('should create a new network from 3 network', function () {
        mockNetworks('Communication Flow', 3, [{from_emp_id: 1, to_emp_id: 5, weight: 2}, {from_emp_id: 1, to_emp_id: 2, weight: 5}]);
        item = mockMetrics('metric_from_3_networks', [3, 4, 2]);
        scope.findOrCreateNetwork(item);
        expect(scope.analyze_data.networks.length).toEqual(4);
        expect(scope.analyze_data.networks[3].original_relation.length).toEqual(4);
      });
    });
  });
});

  // describe('self.toggleIsolateNode', function () {
  //   beforeEach(inject(function ($injector) {
  //     graphService = $injector.get('graphService');
  //     scope.employees = [{ id: 1, gender: 'male', group_id: 1, friendship: 8 },
  //                        { id: 2, gender: 'female', group_id: 1, friendship: 10 },
  //                        { id: 3, gender: 'female', group_id: 2, friendship: 1},
  //                        { id: 4, gender: 'female', group_id: 2, friendship: 1}];
  //     graphService.setNodes(scope.employees);
  //     graphService.setLinks([{from_emp_id: 1, to_emp_id: 2}, {from_emp_id: 3, to_emp_id: 4}]);
  //   }));

  //   describe('if nothing is isolated yet', function () {
  //     beforeEach(function () {
  //       graphService.setIsolated();
  //       spyOn(controller, 'addFilter');
  //       controller.toggleIsolateNode(1, 'single');
  //     });

  //     it('should call addFilter for each neighbour of the node that\'s being isolated and the node itself', function () {
  //       expect(controller.addFilter).toHaveBeenCalledWith('id', 1);
  //       expect(controller.addFilter).toHaveBeenCalledWith('id', 2);
  //     });

  //     it('should set new isolated and isolated_group', function () {
  //       expect(graphService.getIsolated().id).toEqual(1);
  //       expect(graphService.getIsolated().type).toEqual('single');
  //       expect(_.pluck(graphService.getIsolatedGroup(), 'id')).toEqual([2, 1]);
  //     });
  //   });

  //   describe('if some node is isolated', function () {
  //     beforeEach(function () {
  //       graphService.setIsolated(3, 'single');
  //       spyOn(controller, 'removeFilter');
  //       spyOn(controller, 'addFilter');
  //       controller.toggleIsolateNode(1, 'single');
  //     });

  //     it('should call removeFilter for each neighbour of the node that was isolated before and the node itself', function () {
  //       expect(controller.removeFilter).toHaveBeenCalledWith('id', 3);
  //       expect(controller.removeFilter).toHaveBeenCalledWith('id', 4);
  //     });

  //     it('should call addFilter for each neighbour of the node that\'s being isolated and the node itself', function () {
  //       expect(controller.addFilter).toHaveBeenCalledWith('id', 1);
  //       expect(controller.addFilter).toHaveBeenCalledWith('id', 2);
  //     });

  //     it('should set new isolated and isolated_group', function () {
  //       expect(graphService.getIsolated().id).toEqual(1);
  //       expect(graphService.getIsolated().type).toEqual('single');
  //       expect(_.pluck(graphService.getIsolatedGroup(), 'id')).toEqual([2, 1]);
  //     });
  //   });
  // });