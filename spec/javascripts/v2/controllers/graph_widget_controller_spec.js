/*globals describe, it, unused ,expect, beforeEach, angular, mock, module, $controller, document, window, mockController */

describe('graphWidgetController,', function () {
  'use strict';

  var controller, scope;

  var mockMeasureData = function () {
    return {
      'graph_data': {
        'delta_size_in_months': 1,
        'values': [
          [new Date("October 13, 2014 11:13:00"), 11, 1],
          [new Date("October 14, 2014 11:13:00"), 2, 22],
          [new Date("October 15, 2014 11:13:00"), 3, 33],
          [new Date("October 16, 2014 11:13:00"), 44, 4],
          [new Date("October 17, 2014 11:13:00"), 5, 55],
          [new Date("October 18, 2014 11:13:00"), 66, 6]
        ],
      }
    };
  };

  var mockGraphData = function () {
    return [
      { lgroup1: 2, cgroup1: 4, ngroup1: 9, lgroup2: 1, cgroup2: 7, ngroup2: 9, csnapshotid: 1,  date: 'Jan 2014' },
      { lgroup1: 4, cgroup1: 9, ngroup1: 3, lgroup2: 7, cgroup2: 9, ngroup2: 5, csnapshotid: 2, date: 'Feb 2014' },
      { lgroup1: 9, cgroup1: 3.1, ngroup1: 5, lgroup2: 9, cgroup2: 5.0, ngroup2: 6, csnapshotid: 3, date: 'Mar 2014' }];
  };

  var mockScoreList = function () {
    return [
      { score: 20, score_normalize: 8, snapshot_id : 1 },
      { score: 21, score_normalize: 8.4, snapshot_id : 2 },
      { score: 22, score_normalize: 8.8, snapshot_id : 3 },
      { score: 23, score_normalize: 9.2, snapshot_id : 4 }];
  };

  beforeEach(function () {
    var mocked_controller = mockController('graphWidgetController');
    controller = mocked_controller.controller;
    scope = mocked_controller.scope;
    scope.measureData = mockMeasureData();
  });
  unused(module);

  it("should be a valid module", function () {
    expect(controller).toBeDefined();
  });

  describe('init()', function () {

    beforeEach(function () {
      scope.init();
    });

    it('should create scope objects', function () {
      expect(scope.data_for_gvis).toBeDefined();
      expect(scope.name).toBeDefined();
      expect(scope.avg).toBeDefined();
    });
  });

  describe('addScoreFromSnapshot()', function () {
    beforeEach(function () {
      scope.graph_data = mockGraphData();
      scope.score_list = mockScoreList();
    });
    it('should get the score of the last snapshot', function () {
      var score = controller.addScoreFromSnapshot(scope.graph_data[0], 8.4);
      expect(score).toEqual(8);
    });
    it('should get the score of the current snapshot beacuse is first', function () {
      var score = controller.addScoreFromSnapshot(scope.graph_data[-1], 8);
      expect(score).toEqual(8);
    });
    it('should get the score of the current snapshot beacuse is first', function () {
      var score = controller.addScoreFromSnapshot(scope.graph_data[2], 8.4);
      expect(score).toEqual(8.8);
    });
  });
});
