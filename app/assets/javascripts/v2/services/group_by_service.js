/*globals angular, _*/
angular.module('workships.services').factory('groupByService', function (dataModelService, utilService) {
  'use strict';
  var gb = {};
  var dm = dataModelService;

  gb.groupEmployeesBy = function (employees_ids, groupBy) {
    var res = {};
    var employees = dm.getEmployeesByIds(employees_ids);
    res.unknown = [];
    _.each(employees, function (e) {
      if (e[groupBy] && e[groupBy].toString().length > 0) {
        if (!res[e[groupBy]]) {
          res[e[groupBy]] = [];
        }
        res[e[groupBy]].push(e.id);
      } else {
        res.unknown.push(e.id);
      }
    });
    return res;
  };

  gb.groupByEmployeeAndAttr = function (employees_ids, e_id, groupBy) {
    var attr = dm.getEmployeeById(e_id)[groupBy];
    if (!attr || attr.length === 0) {
      return;
    }
    var res = {};
    res[attr] = [];
    if (groupBy === 'group_name') {
      var g = dm.getGroupBy(attr);
      res[attr] = _.intersection(employees_ids, g.employees_ids);
    } else if (groupBy === 'manager_id') {
      var e = dm.getEmployeeById(attr);
      res[attr] = _.intersection(employees_ids, e.subordinates);
      res[attr].push(e.id);
    } else {
      var employees = dm.getEmployeesByIds(employees_ids);
      _.each(employees, function (e) {
        if (attr === e[groupBy]) {
          res[attr].push(e.id);
        }
      });
    }
    return res;
  };

  function oneGroupContaninesTheOtherEmployees(g1, g2) {
    var intersection, smaller_group;
    if (g1.employees_ids.length > g2.employees_ids.length) {
      smaller_group = g2;
    } else {
      smaller_group = g1;
    }
    intersection = _.intersection(g1.employees_ids, g2.employees_ids);
    if (intersection.length === smaller_group.employees_ids.length) {
      return smaller_group;
    }
  }

  function removeIrrelevantGroups(groups_obj) {
    var rejects = [];
    var group_names = utilService.getObjKeys(groups_obj);
    var i, j, smaller_group, g1, g2;
    for (i = 0; i < group_names.length; i++) {
      for (j = i + 1; j < group_names.length; j++) {
        g1 = groups_obj[group_names[i]];
        g2 = groups_obj[group_names[j]];
        smaller_group = oneGroupContaninesTheOtherEmployees(g1, g2);
        if (smaller_group) {
          rejects.push(dm.getGroupBy(smaller_group.id).name);
        }
      }
    }
    _.each(rejects, function (group_name) {
      delete groups_obj[group_name];
    });
    return groups_obj;
  }

  gb.groupByFormalStructure = function (employees_ids) {
    var res = {};
    var g;
    var group_by_res = gb.groupEmployeesBy(employees_ids, 'group_name');
    delete group_by_res.unknown;
    var group_names = Object.keys(group_by_res);
    _.each(group_names, function (name) {
      g = dm.getGroupBy(name);
      res[name] = {
        id: g.id,
        employees_ids: _.intersection(employees_ids, g.employees_ids),
      };
    });
    return removeIrrelevantGroups(res);
  };

  gb.groupByGroupId = function (g_id, employees_ids) {
    var res = {};
    var child_group = dm.getGroupBy(g_id);
    var parent = dm.getGroupBy(child_group.parent);
    var obj = {};
    obj.child_ids = parent.child_groups;
    obj.employees_ids = _.intersection(parent.employees_ids, employees_ids);
    obj.id = child_group.parent;
    res[parent.name] = obj;
    return res;
  };

  return gb;

});
