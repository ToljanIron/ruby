/*globals describe, it, expect, beforeEach, angular, mock, module, inject, unused, _ */
describe('dataModelService,', function () {
  'use strict';

  beforeEach(angular.mock.module('workships.services'));

  var service;

  beforeEach(inject(function (dataModelService) {
    service = dataModelService;
  }));

  it('should be defined', function () {
    expect(service.getEmployees).toBeDefined();
    expect(service.getGroups).toBeDefined();
    expect(service.getSnapshots).toBeDefined();
    expect(service.getPins).toBeDefined();
    expect(service.getFormalStructure).toBeDefined();
    expect(service.getBreadCrumbs).toBeDefined();
    expect(service.getDefaultGroupId).toBeDefined();
    expect(service.getAnalyseFlags).toBeDefined();
    expect(service.getAnalyze).toBeDefined();
    expect(service.getMeasures).toBeDefined();
    expect(service.getFlags).toBeDefined();
    expect(service.getExternalDataList).toBeDefined();
    expect(service.getGroupMeasures).toBeDefined();
    expect(service.getNewMetric).toBeDefined();
  });

  describe('getAnalyze', function () {
    it('Should create a cache of size 2', function () {
      var res = service.createCache('cds_get_analyze_data_cache_test', 2).info();
      expect(res.id).toEqual('cds_get_analyze_data_cache_test');
      expect(res.capacity).toEqual(2);
    });

    it('Should populate the cache with 1 object', function () {
      var cache = service.createCache('cds_get_analyze_data_cache_test', 3);
      service.putValueInCache(cache, 'ObjA', 4);
      var res = cache.info();
      expect(res.size).toEqual(1);
    });

    it('Should verify LRU machanism works properly', function() {
      var cache = service.createCache('cds_get_analyze_data_cache_test', 2);
      service.putValueInCache(cache, 'ObjA', 1);
      service.putValueInCache(cache, 'ObjB', 2);
      service.putValueInCache(cache, 'ObjC', 4);
      var res = service.getValueFromCache(cache, 'ObjB');
      expect(res).toEqual(2);
      res = service.getValueFromCache(cache, 'ObjA');
      expect(res).toEqual(undefined);
    });
  });

  describe('getDefaultGroup', function () {
    it('should id of highest highest group', function () {
      service.mock();
      var res = service.getDefaultGroupId();
      expect(res).toBe(1);
    });
  });

  it('getters return a promise', function () {
    var targets = {
      'getEmployees': 'employees',
      'getGroups': 'groups',
      'getSnapshots': 'snapshots',
      'getPins': 'pins',
      'getFormalStructure': 'formal_structure',
      'getMeasures': 'measures',
      'getFlags': 'flags',
      'getColors': 'colors',
    };
    _.each(Object.keys(targets), function (t) {
      expect(service[t]().then).toBeDefined();
    });
  });

  describe('getBreadCrumbs() should array of groups from given child to highest group', function () {
    beforeEach(function () {
      service.mock();
    });

    it('when highest group is given', function () {
      var g1 = service.groups[0];
      var res = service.getBreadCrumbs(g1.id, 'group');
      expect(res).toEqual([g1]);
    });
    it('when subgroup is given', function () {
      var g1 = service.groups[0];
      var g2 = service.groups[1];
      var g3 = service.groups[2];
      var res = service.getBreadCrumbs(g3.id, 'group');
      expect(res).toEqual([g1, g2, g3]);
    });
    it('when pin is given', function () {
      var res;
      _.each(service.pins.active, function (p) {
        res = service.getBreadCrumbs(p.id, 'pin');
        expect(res).toEqual([p]);
      });
    });
  });

  describe('getSearchList()', function () {
    beforeEach(function () {
      service.mock();
    });
    it('should return a list of groups+pins', function () {
      var res = service.getSearchList()();
      expect(res.length).toBe(service.groups.length + service.pins.active.length);
    });
    it('should contain name,id, type of each group/pin', function () {
      var lst = service.getSearchList()();
      var res;
      _.each(service.groups, function (g) {
        res = _.find(lst, function (obj) {
          return obj.type === 'group' && obj.name === g.name && obj.id === g.id;
        });
        expect(res).toBeDefined();
      });
      _.each(service.pins.active, function (p) {
        res = _.find(lst, function (obj) {
          return obj.type === 'pin' && obj.name === p.name && obj.id === p.id;
        });
        expect(res).toBeDefined();
      });
    });
  });

  describe('getColorsByName()', function () {
    beforeEach(function () {
      service.mock();
    });
    it('should get attribute name + group by_name  to normal attribute and  return a color', function () {
      var group_by = 'gender';
      var attr_name = 'male';
      var res = service.getColorsByName(group_by, attr_name);
      expect(res).toBe(service.colors.attributes[attr_name]);
    });
    it(' should get g_id and sructre and return color', function () {
      var g_id = 1;
      var group_by = 'formal_structure';
      var res = service.getColorsByName(group_by, g_id);
      expect(res).toBe(service.colors.g_id[g_id]);
    });
    it(' should get manager_id and formal and return color', function () {
      var manager_id = 1;
      var group_by = 'manager_id';
      var res = service.getColorsByName(group_by, manager_id);
      expect(res).toBe(service.colors.manager_id[manager_id]);
    });
  });

  describe('getStructureHeight', function () {
    beforeEach(function () {
      service.mock();
    });
    it('should return the lowset group level', function () {
      var res = service.getStructureHeight();
      expect(res).toBe(2);
    });
  });

  describe('getGroupDirectChildsList', function () {
    beforeEach(function () {
      service.mock();
    });
    it('should return 2 sub group of when the group_id is 2 ', function () {
      var res = service.getGroupDirectChildsList(2);
      expect(res.length).toBe(2);
    });
    it('should return 1 sub group when the group_id is 1 ', function () {
      var res = service.getGroupDirectChildsList(1);
      expect(res.length).toBe(1);
    });
    it('should return undefined sub group when the group_id is [] ', function () {
      var res = service.getGroupDirectChildsList(0);
      expect(res.length).toBe(0);
    });
  });

  describe('getAllEmpsNumber()', function () {
    beforeEach(function () {
      service.mock();
    });
    it('should return the number of employees', function () {
      var res = service.getAllEmpsNumber();
      expect(res).toBe(60);
    });
    it(' getEmployeeByEmail() , should return the name of employee', function () {
      var res = service.getEmployeeByEmail('email5@mail.com');
      expect(res.id).toBe(5);
    });
  });

  describe('get the number of pins', function () {
    beforeEach(function () {
      service.mock();
    });
    it('should return the number of all preset', function () {
      expect(service.getNumberOfPreset()).toEqual(6);
    });
  });

  describe('getNewMetric', function () {
    beforeEach(function () {
      service.mock();
    });
    it('should return empty obj when no metric', function () {
      var res = service.getNewMetric('AA', 'metric');
      expect(res).toEqual(undefined);
    });
    it('should return empty obj when no flag', function () {
      var res = service.getNewMetric('NO FLAG', 'flag');
      expect(res).toEqual(undefined);
    });
    it('should return metric obj when find metric', function () {
      var mocked = service.mesures['1'];
      var res = service.getNewMetric(1, 'metric');
      expect(res).toEqual(mocked);
    });
    it('should return flag obj when find flag', function () {
      var mocked = service.flags['0'];
      var res = service.getNewMetric(3, 'flag');
      expect(res).toEqual(mocked);
    });
  });
});
