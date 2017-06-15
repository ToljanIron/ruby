/*globals describe, it, expect, beforeEach, angular, mock, module, inject, unused, _ */
describe('groupByService,', function () {
  'use strict';

  beforeEach(angular.mock.module('workships.services'));

  var service, dm;
  var helper = {};
  helper.filterByAttrValue = function (empArr, attr, value) {
    return _.filter(empArr, function (e) {
      return e[attr] === value;
    });
  };

  beforeEach(inject(function (groupByService, dataModelService) {
    service = groupByService;
    dm = dataModelService;
    dm.mock();
  }));

  it('should be defined', function () {
    expect(service).toBeDefined();
  });

  describe(',groupEmployeesBy()', function () {

    describe(',should divide given employees to groups by attribute', function () {
      it(',gender on whole company', function () {
        var employees = dm.groups[0].employees_ids;
        var res = service.groupEmployeesBy(employees, 'gender');
        var males = helper.filterByAttrValue(dm.employees, 'gender', 'male');
        var females = helper.filterByAttrValue(dm.employees, 'gender', 'female');
        expect(res.male.length).toBe(males.length);
        expect(res.female.length).toBe(females.length);
        expect(res.unknown.length).toBe(dm.employees.length - males.length - females.length);
      });
      it(',gender on subgroup', function () {
        var employees = dm.groups[1].employees_ids;
        var res = service.groupEmployeesBy(employees, 'gender');
        var relavent_employees = _.filter(dm.employees, function (e) {
          return e.group_id !== 1;
        });
        var males = helper.filterByAttrValue(relavent_employees, 'gender', 'male');
        var females = helper.filterByAttrValue(relavent_employees, 'gender', 'female');
        expect(res.male.length).toBe(males.length);
        expect(res.female.length).toBe(females.length);
        expect(res.unknown.length).toBe(relavent_employees.length - males.length - females.length);
      });
      it(',rank on whole company', function () {
        var employees = dm.groups[0].employees_ids;
        var res = service.groupEmployeesBy(employees, 'rank');
        var rank_0 = helper.filterByAttrValue(dm.employees, 'rank', 'rank 0');
        var rank_1 = helper.filterByAttrValue(dm.employees, 'rank', 'rank 1');
        var rank_2 = helper.filterByAttrValue(dm.employees, 'rank', 'rank 2');
        expect(res['rank 0'].length).toBe(rank_0.length);
        expect(res['rank 1'].length).toBe(rank_1.length);
        expect(res['rank 2'].length).toBe(rank_2.length);
        expect(res.unknown.length).toBe(dm.employees.length - rank_0.length - rank_1.length - rank_2.length);
      });
      it(',rank on subgroup', function () {
        var employees = dm.groups[1].employees_ids;
        var res = service.groupEmployeesBy(employees, 'rank');
        var relavent_employees = _.filter(dm.employees, function (e) {
          return e.group_id !== 1;
        });
        var rank_0 = helper.filterByAttrValue(relavent_employees, 'rank', 'rank 0');
        var rank_1 = helper.filterByAttrValue(relavent_employees, 'rank', 'rank 1');
        var rank_2 = helper.filterByAttrValue(relavent_employees, 'rank', 'rank 2');
        expect(res['rank 0'].length).toBe(rank_0.length);
        expect(res['rank 1'].length).toBe(rank_1.length);
        expect(res['rank 2'].length).toBe(rank_2.length);
        expect(res.unknown.length).toBe(relavent_employees.length - rank_0.length - rank_1.length - rank_2.length);
      });
    });
  });
  describe(', groupByEmployeeAndAttr()', function () {
    var e;
    beforeEach(function () {
      e = dm.employees[0];
    });
    describe('should return group of employees with same attribute as e_id', function () {
      it('rank on whole company', function () {
        var employees_ids = dm.groups[0].employees_ids;
        var res = service.groupByEmployeeAndAttr(employees_ids, e.id, 'rank');
        var employees = dm.employees;
        var matching_employees = helper.filterByAttrValue(employees, 'rank', e.rank);
        expect(res[e.rank].length).toBe(matching_employees.length);
      });

      it('role_type on sub group', function () {
        var employees_ids = dm.groups[1].employees_ids;
        var res = service.groupByEmployeeAndAttr(employees_ids, e.id, 'role_type');
        var relavent_employees = _.filter(dm.employees, function (e) {
          return e.group_id !== 1;
        });
        var matching_employees = helper.filterByAttrValue(relavent_employees, 'role_type', e.role_type);
        expect(res[e.role_type].length).toBe(matching_employees.length);
      });
    });
    describe('when attr===group_name, should return all employees of group & nested groups', function () {
      it('group_name on whole company', function () {
        e.group_name = 'G1';
        var employees_ids = dm.groups[0].employees_ids;
        var res = service.groupByEmployeeAndAttr(employees_ids, e.id, 'group_name');
        var employees = dm.employees;
        expect(res[e.group_name].length).toBe(employees.length);
      });
    });
  });
  describe(', groupByFormalStructure() should devide employees into direct groups', function () {
    describe(', on whole company', function () {
      var employees_ids;
      var res;
      beforeEach(function () {
        employees_ids = dm.groups[0].employees_ids;
        res = service.groupByFormalStructure(employees_ids);
      });
      it(', should return all direct groups', function () {
        expect(Object.keys(res).length).toBe(2);
      });
      it(', each group should hava id, name and intersection of the employees', function () {
        var g3 = dm.groups[2];
        var g4 = dm.groups[3];
        expect(res.G3.id).toBe(g3.id);
        expect(res.G3.employees_ids).toEqual(g3.employees_ids);
        expect(res.G4.id).toBe(g4.id);
        expect(res.G4.employees_ids).toEqual(g4.employees_ids);
      });
    });
    describe(', on subgroup', function () {
      var employees_ids;
      var res;
      beforeEach(function () {
        employees_ids = dm.groups[2].employees_ids;
        res = service.groupByFormalStructure(employees_ids);
      });
      it(', should return all direct groups', function () {
        expect(Object.keys(res).length).toBe(1);
      });
      it(', each group should hava id, name and intersection of the employees', function () {
        var g3 = dm.groups[2];
        expect(res.G3.id).toBe(g3.id);
        expect(res.G3.employees_ids).toEqual(_.intersection(employees_ids, g3.employees_ids));
      });
    });
    describe(', when higher group has employees too', function () {
      var employees_ids;
      var res;
      beforeEach(function () {
        var e = {
          id: 999,
          group_name: 'G1'
        };
        dm.employees.push(e);
        dm.groups[0].employees_ids.push(e.id);
        employees_ids = dm.groups[0].employees_ids;
        res = service.groupByFormalStructure(employees_ids);
      });
      it(', should return all direct groups', function () {
        expect(Object.keys(res)[0]).toBe('G1');
      });
    });
  });
  describe(', groupByGroupId should return parent group', function () {
    it(', should return parent group with intersection of the employees', function () {
      var g2 = dm.groups[1];
      var g3 = dm.groups[2];
      var employees_ids = _.filter(g2.employees_ids, function (id) {
        return id % 2 === 0;
      });
      var res = service.groupByGroupId(g3.id, employees_ids);
      expect(Object.keys(res)[0]).toBe(g2.name);
      expect(res[g2.name].child_ids).toEqual(g2.child_groups);
      expect(res[g2.name].employees_ids).toEqual(_.intersection(g2.employees_ids, employees_ids));
    });
  });
});
