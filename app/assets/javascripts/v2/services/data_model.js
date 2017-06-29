/*globals angular, _, unused*/
/*
* dataModelService is the clients DB. data is received from the server via, or generated at the client side during the session.
* The proper flow is:
* when the obj is asked, check if it is already available.
   - if its is return it as a promise
   - if its not, use ajaxService to get its promise
* notes:
*  - dataModelService should only hold data objects. no functionally except for getters.
*  - to avoid unnecessary computations, prefer getting the obj exactly as you wish use it from the server.
*  - when an obj is received, you can derive additional objects from it.
*  - don't use the dataModelService to upload data to the server.
*  - don't use the dataModelService to change objects. use the getter, and do your modification. remember your changes will affect others that use the same object. if you plan on doing destructive work, deep clone the obj at you side.
*/

angular.module('workships.services').factory('dataModelService', function (ajaxService, $q, $cacheFactory) {
  'use strict';
  var dm = {};
  var COMPANY_ID = 1; // _TODO WTF?? company_id should allways be an argument, never const.
  var SAVED_AS_DRAFT = 1; // what is that? move out of dm.


  var cds_get_analyze_data_cache = null;
  // var GENERATE = 2;

  /************** helpers **************/

  // _TODO can we get the data in the right way instead of doing this conversion 
  function convertTheScoreToFloat(external_data_list) {
    _.each(external_data_list, function (metric) {
      _.each(metric.score_list, function (score_to_snapshot) {
        score_to_snapshot.score = parseFloat(score_to_snapshot.score);
        score_to_snapshot.score_normalize = parseFloat(score_to_snapshot.score_normalize);
      });
    });
  }


  // _TODO use Group dic
  function findGroupById(group_id) {
    return _.find(dm.groups, function (g) {
      return g.id === group_id;
    });
  }

  // _TODO should move out of dm
  dm.findPinById = function (pin_id) {
    return _.find(_.union(dm.pins.active, dm.pins.drafts), function (p) {
      return p.id === pin_id;
    });
  };

  // _TODO should move out of dm
  dm.getNumberOfPreset = function () {
    return (dm.pins.active.length + dm.pins.drafts.length + dm.pins.in_progress.length);
  };

  // _TODO should move out of dm
  dm.changePresetName = function (pid, preset_name) {
    var preset = dm.findPinById(pid);
    preset.name = preset_name;
  };

  // _TODO move into parent function
  function getBreadCrumbsFromGroup(id) {
    var res = [];
    var group = findGroupById(id);
    while (group && res.unshift(group)) {
      group = findGroupById(group.parent);
    }
    return res;
  }

  // _TODO move into parent function
  function getBreadCrumbsFromPin(id) {
    return [dm.findPinById(id)];
  }

  function deriveAdditionalGroupsData() {
    var max = 0;
    var dic = {};
    _.each(dm.groups, function (g) {
      dic[g.id] = g;
      dic[g.name] = g;
      max = Math.max(max, g.level);
    });
    dm.getGroupBy = function (id_or_name) {
      return dic[id_or_name];
    };
    dm.getStructureHeight = function () {
      return max;
    };
    dm.getGroupHeight = function (id) {
      return (dm.getGroupBy(id).level);
    };
    dm.getDivisionName = function (id) {
      var grous_in_level_2 = dm.getGroupByHeight(1);
      if (_.include(grous_in_level_2, id)) {
        return null;
      }
      var res, group_in_divsion;
      _.each(grous_in_level_2, function (group_id) {
        group_in_divsion = dm.getGroupBy(group_id).child_groups;
        if (_.include(group_in_divsion, id)) {
          res = dm.getGroupBy(group_id).name;
        }
      });
      return res;
    };
    dm.getGroupDirectChilds = function (g_id) {
      return _.filter(dm.groups, function (g) {
        return (g.parent === g_id);
      });
    };
    dm.getGroupDirectChildsList = function (g_id) {
      var res = [];
      _.each(dm.groups, function (g) {
        if (g.parent === g_id) {
          res.push(g.id);
        }
      });
      return res;
    };

    // only for test
    dm.addToDictionaries = function (group) {
      dic[group.id] = group;
      dic[group.name] = group;
    };
  }

  function createEmployeesDictionary() {
    var dic = {};
    _.each(dm.employees, function (e) {
      dic[e.id] = e;
    });
    dm.getEmployeeById = function (id) {
      return dic[id];
    };

    dm.getFormalHeight = function (employees_ids) {
      var max = 0;
      _.each(employees_ids, function (e_id) {
        var employee = dm.getEmployeeById(e_id);
        max = Math.max(max, employee.formal_level);
      });
      return max;
    };
    dm.getAllEmpsNumber = function () {
      if (dm.employees) {
        return _.reject(dm.employees, {email: 'other@mail.com' }).length;
      }
    };
    dm.getEmployeeByEmail = function (emp_email) {
      return _.find(dm.employees, { email: emp_email});
    };
    dm.getEmployeeByHeight = function (level, employees_ids) {
      var res = [];
      res = _.filter(employees_ids, function (e_id) {
        var employee = dm.getEmployeeById(e_id);
        return (employee.formal_level === level);
      });
      return res;
    };

    dm.getEmployeesByGroupId = function (g_id) {
      var res = [];
      res = _.where(dm.employees, { group_id: g_id});
      return res;
    };
  }

  function createEmployeesRelationWeight(id) {
    var memo = [];
    var res = [];
    var list_of_relation = _.filter(dm.employee_relations, function (rel) {
      return (rel.to_emp_id === id || rel.from_emp_id === id);
    });
    _.each(list_of_relation, function (rel) {
      var emp_id, weight;
      if (rel.to_emp_id === id) {
        emp_id = rel.from_emp_id;
        weight = rel.weight;
      } else {
        emp_id = rel.to_emp_id;
        weight = rel.weight;
      }
      if (!memo[emp_id]) {
        memo[emp_id] = true;
        res[emp_id] = {emp_id: emp_id, weight: 0};
      }
      res[emp_id].weight += weight;
    });
    var sum = 0;
    var employees_list = _.sortBy(_.values(res), function (obj) {
      if (obj !== undefined) {
        sum += obj.weight;
        return -obj.weight;
      }
    });
    var arr = [];
    var i, employee_deatils;
    if (sum > 0) {
      var other = 100;
      for (i = 0; i <= 3; i++) {
        if (!employees_list[i]) {
          return;
        }
        arr[i] = {};
        arr[i].emp_id = employees_list[i].emp_id;
        employee_deatils = dm.getEmployeeById(arr[i].emp_id);
        if (employee_deatils) {
          arr[i].name = employee_deatils.first_name + ' ' + employee_deatils.last_name;
          arr[i].img = employee_deatils.img_url;
          arr[i].size = Math.round((employees_list[i].weight * 100) / sum);
          other -= arr[i].size;
        }
      }
      arr[i] = {};
      arr[i].name = 'other';
      arr[i].size = other;
    }
    return arr;
  }

  // _TODO can we get the data in the write way instead of doing this computation?
  function addNetworkToMeasures(measures) {
    var METRICS_GROUP = {
      'Communication flow' : ["Collaboration", "Central", "Delegator", "Knowledge Distributor", "Centrality", "Politician", "In The Loop", "Politically Active", "Total Activity Centrality"],
      Advice : ["Expert", "Seek Advice"],
      Friendship : ["Popular", "Most Social Power", 'Socially Active'],
      Trust : ["Trusted", "Trusting"]
    };
    _.each(measures, function (metric) {
      metric.networkType = 'Others';
      if (_.include(METRICS_GROUP['Communication flow'], metric.graph_data.measure_name)) {
        metric.networkType = 'Communication flow';
      }
      if (_.include(METRICS_GROUP.Advice, metric.graph_data.measure_name)) {
        metric.networkType = 'Advice';
      }
      if (_.include(METRICS_GROUP.Friendship, metric.graph_data.measure_name)) {
        metric.networkType = 'Friendship';
      }
      if (_.include(METRICS_GROUP.Trust, metric.graph_data.measure_name)) {
        metric.networkType = 'Trust';
      }
    });
  }


  var metric       = 1;
  var flag         = 2;
  var gauge        = 5;
  var higher_level = 6;
  var wordcloud = 7;

  dm.getDataForLevel = function (company_metric_id, algorithm_type) {
    if (company_metric_id === undefined || algorithm_type === undefined || (company_metric_id < 0 && algorithm_type !== wordcloud)) {
      return false;
    }
    var type = '';
    if (algorithm_type === flag) {
      type = 'flag';
    } else if (algorithm_type === metric) {
      type = 'metric';
    } else if (algorithm_type === gauge || algorithm_type === higher_level) {
      type = 'gauge';
    } else if (algorithm_type === wordcloud) {
      type = 'wordcloud';
    }
    if (type === '') {
      return null;
    }
    return dm.getNewMetric(company_metric_id, type);
  };


  dm.getNewMetric = function (company_metric_id, type) {
    var res = null;
    if (type === 'metric') {
      if (dm.mesures) {
        res = _.find(dm.mesures, function (metric) { return metric.company_metric_id === company_metric_id; });
      }
    } else if (type === 'flag') {
      res = _.find(dm.flags, function (flag) { return flag.company_metric_id === company_metric_id; });
    } else if (type === 'gauge') {
      res = _.find(dm.gauges, function (gauge) { return gauge.company_metric_id === company_metric_id; });
    } else if (type === 'wordcloud') {
      res = dm.wordcloud;
    }
    return res;
  };

  dm.getGaugeParam = function (company_metric_id, param) {
    var res = dm.getNewMetric(company_metric_id, 'gauge');
    if (!res) { return; }
    return (res[param]);
  };


  // _TODO should move out of dm
  function removePrestFromPinList(pid) {
    var preset = dm.findPinById(pid);
    var pin_list;
    if (preset.status === 'draft') {
      pin_list = dm.pins.drafts;
    } else {
      pin_list = dm.pins.active;
    }
    _.remove(pin_list, function (pin) {
      return pin.id === pid;
    });
  }

  /******************* mocker *******************/

  dm.mock = function () {
    var service = dm;
    var updateGroupsWithEmployees = function () {
      var g1 = service.groups[0];
      var g2 = service.groups[1];
      var g3 = service.groups[2];
      var g4 = service.groups[3];
      _.each(service.employees, function (e) {
        g1.employees_ids.push(e.id);
        g2.employees_ids.push(e.id);
        if (e.group_id === 3) {
          g3.employees_ids.push(e.id);
        }
        if (e.group_id === 4) {
          g4.employees_ids.push(e.id);
        }
      });
    };
    var mockFormalStructure = function () {
      service.formal_structure = [{
        group_id: 1,
        child_groups: [{
          group_id: 2,
          child_groups: [{
            group_id: 3,
            child_groups: []
          }, {
            group_id: 4,
            child_groups: []
          }]
        }]
      }];
    };

    service.addGroup = function (id) {
      var group =  {
          id: id,
          child_groups: [],
          employees_ids: [],
          name: 'G' + id,
          parent: null,
          level: 0
        };
      service.groups.push(group);
      service.addToDictionaries(group);
    };

    var mockGroups = function () {
      service.groups = [
        {
          id: 1,
          child_groups: [2],
          employees_ids: [],
          name: 'G1',
          parent: null,
          level: 0
        },
        {
          id: 2,
          child_groups: [3, 4],
          employees_ids: [],
          name: 'G2',
          parent: 1,
          level: 1
        },
        {
          id: 3,
          child_groups: [],
          employees_ids: [],
          name: 'G3',
          parent: 2,
          level: 2
        },
        {
          id: 4,
          child_groups: [],
          employees_ids: [],
          name: 'G4',
          parent: 2,
          level: 2
        }];
    };

    var mockPins = function () {
      service.pins = {};
      service.pins.active = [
        {
          id: 1,
          name: 'pin1',
          definition: { conditions: [{param: 'gender', vals: ['1']}],
            groups: [1, 3],
            employees: ['email3@mail.com']},
          ui_definition: { conditions: [{ param: 'gender', vals: ['female']}],
            groups: [1, 3],
            employees: ['email3@mail.com']}
        }, {
          id: 2,
          name: 'pin2'
        }
      ];
      service.pins.drafts = [{
        id: 1,
        name: 'pin5'
      }, {
        id: 4,
        name: 'pin20'
      }];
      service.pins.in_progress = [{
        id: 20,
        name: 'prog1'
      }, {
        id: 21,
        name: 'prog2'
      }];
    };

    var mockEmployees = function () {
      var i, g_id;
      service.employees = [];
      for (i = 0; i < 50; i++) {
        g_id = Math.random() > 0.5 ? 3 : 4;
        service.employees.push({
          id: i,
          email: 'email' + i + '@mail.com',
          gender: Math.random() > 0.5 ? 'male' : 'female',
          group_id: g_id,
          group_name: 'G' + g_id,
          rank: 'rank ' + i % 3,
          role_type: Math.random() > 0.5 ? 'role A' : 'role B',
          age_group: 'age ' + i % 4
        });
      }
      for (i = 50; i < 60; i++) {
        service.employees.push({
          id: i,
          group_id: Math.random() > 0.5 ? 3 : 4
        });
      }
      updateGroupsWithEmployees();
    };

    var mockColors = function () {
      service.colors = {};
      service.colors.attributes = {
        male: 'dfe23',
        female: 'efd23'
      };
      service.colors.g_id = {
        1: 're43222',
        2: 'erfd34',
        3: 'uyt4t'
      };
      service.colors.manager_id = {
        1: 'fdfdfd',
        2: 'dsdsds'
      };
    };

    var mockMetricsAndFlags = function () {
      service.mesures = {
        1: { company_metric_id: 1, measure_name: 'Expert', snapshots: []},
        2: { company_metric_id: 2, measure_name: 'Central', snapshots: [] }
      };
      service.flags = {
        0: { company_metric_id: 3, measure_name: 'At Risk of Leaving'},
        1: { company_metric_id: 4, measure_name: 'Most Promising Talent'}
      };
    };
    mockFormalStructure();
    mockGroups();
    mockPins();
    mockEmployees();
    mockColors();
    mockMetricsAndFlags();
    service.updateDictionaries();
  };

  /************** Promises **************/

  var pending_results = 0;
  var result_queue = [];
  function deferMe(the_function) {
    if (the_function.deferred === undefined) {
      the_function.deferred = $q.defer();
      the_function.deferred_pending = true;
    }
    return the_function.deferred;
  }

  function resolveQueue() {
    if (pending_results <= 0) {
      _.each(result_queue, function (r) {
        r();
      });
      result_queue = [];
      pending_results = 0;
    }
  }

  function addToResultQueue(the_func) {
    pending_results--;
    result_queue.push(the_func);
    resolveQueue();
  }

  function promiseThat(the_function, method, url, params, data_model, succ, err, reset) {
    if (the_function.deferred_pending && (!dm[data_model] || reset)) {
      var promise = ajaxService.getPromise(method, url, params);
      pending_results++;
      promise.then(function (response) {
        addToResultQueue(function () {
          if (dm[data_model] && !reset) { console.warn("Warning: You already have dm." + data_model + " loaded!!!"); }
          succ(response.data);
          the_function.deferred = undefined;
        });
      }, function () {
        addToResultQueue(function () {
          err();
          the_function.deferred = undefined;
        });
      });

      the_function.deferred_pending = false;
    }
    return $q.when(dm[data_model] || the_function.deferred.promise);
  }

  dm.getEmployees = function (sid) {
    if (sid === undefined) { sid = 0; }
    var deferred = deferMe(dm.getEmployees);
    var method = 'GET';
    var url = "get_employees";
    var params = {sid: sid};

    var succ = function (data) {
      dm.employees = data.employees;
      createEmployeesDictionary();
      deferred.resolve(dm.employees);
    };

    var err = function () {
      dm.employees = undefined;
      deferred.resolve(dm.employees);
    };

    return promiseThat(dm.getEmployees, method, url, params, 'employees', succ, err);
  };

  dm.getQuestionnaires = function (reset) {
    if (reset) {
      dm.questionnaires = undefined;
    }
    var deferred = deferMe(dm.getQuestionnaires);
    var method = 'GET';
    var url = "get_questionnaires";
    var params = {};
    /* istanbul ignore next */
    var succ = function (data) {
      dm.questionnaires = data.questionnaires;
      deferred.resolve(dm.questionnaires);
    };
    /* istanbul ignore next */
    var err = function () {
      dm.questionnaires = undefined;
      deferred.resolve(dm.questionnaires);
    };

    return promiseThat(dm.getQuestionnaires, method, url, params, 'questionnaires', succ, err);

  };

  dm.getQuestionnaireParticipantsByQuestionnaire = function () {
    var deferred = deferMe(dm.getQuestionnaireParticipantsByQuestionnaire);
    if (dm.questionnaire_participants) {
      deferred.resolve(dm.questionnaire_participants);
    }
    var method = 'GET';
    var url = "get_questionnaire_participants";
    var params = {};
    /* istanbul ignore next */
    var succ = function (data) {
      dm.questionnaire_participants = data.questionnaire_array;
      deferred.resolve(dm.questionnaire_participants);
    };
    /* istanbul ignore next */
    var err = function () {
      dm.questionnaire_partiicpants = undefined;
      deferred.resolve(dm.questionnaire_participants);
    };

    return promiseThat(dm.getQuestionnaireParticipantsByQuestionnaire, method, url, params, 'questionnaire_participants', succ, err);

  };

  dm.fetchGroupIdsFromOverlayEntity = function (show_groups) {
    return _.pluck(_.filter(dm.entity_group, function(group) { return _.include(show_groups, group.name);}),'id');
  };

  dm.getOverlayEntityGroup = function () {
    var deferred = deferMe(dm.getOverlayEntityGroup);
    var method = 'GET';
    var url = "API/get_overlay_entity_group";
    var params = {};
    /* istanbul ignore next */
    var succ = function (data) {
      dm.entity_group = data;
      deferred.resolve(dm.entity_group);
    };
    /* istanbul ignore next */
    var err = function () {
      dm.entity_group = undefined;
      deferred.resolve(dm.entity_group);
    };

    return promiseThat(dm.getOverlayEntityGroup, method, url, params, 'entity_group', succ, err);
  };

  dm.getOverlayEntityTypes = function () {
    var deferred = deferMe(dm.getOverlayEntityTypes);
    var method = 'GET';
    var url = "API/get_overlay_entity_types";
    var params = {};
    /* istanbul ignore next */
    var succ = function (data) {
      dm.entity_type = data;
      deferred.resolve(dm.entity_type);
    };
    /* istanbul ignore next */
    var err = function () {
      dm.entity_type = undefined;
      deferred.resolve(dm.entity_type);
    };

    return promiseThat(dm.getOverlayEntityTypes, method, url, params, 'entity_type', succ, err);
  };

  dm.getKeywords = function () {
    var deferred = deferMe(dm.getKeywords);
    var method = 'GET';
    var url = "/API/get_keywords";
    var params = {};
    /* istanbul ignore next */
    var succ = function (data) {
      dm.keywords = data;
      deferred.resolve(dm.keywords);
    };
    /* istanbul ignore next */
    var err = function () {
      dm.keywords = undefined;
      deferred.resolve(dm.keywords);
    };

    return promiseThat(dm.getKeywords, method, url, params, 'keywords', succ, err);
  };

  // dm.getOverlaySnapshotData = function (overlay_groups_id, ids, group_id, s_id, reset) {
  //   if (reset) {
  //     dm.overlay_snapshot_data = undefined;
  //   }
  //   var deferred = deferMe(dm.getOverlaySnapshotData);
  //   var method = 'GET';
  //   var url = "API/get_overlay_snapshot_data";
  //   var params = {};
  //   if (overlay_groups_id) { params.oegid = JSON.stringify(overlay_groups_id); }
  //   if (ids) { params.ids = JSON.stringify(ids); }
  //   if (group_id) { params.gid = group_id; }
  //   if (s_id) { params.snapshot_id = s_id; }
  //   /* istanbul ignore next */
  //   var succ = function (data) {
  //     dm.overlay_snapshot_data = data;
  //     deferred.resolve(dm.overlay_snapshot_data);
  //   };
  //   /* istanbul ignore next */
  //   var err = function () {
  //     dm.overlay_snapshot_data = undefined;
  //     deferred.resolve(dm.overlay_snapshot_data);
  //   };

  //   return promiseThat(dm.getOverlaySnapshotData, method, url, params, 'overlay_snapshot_data', succ, err);
  // };

  dm.getGroups = function (sid) {
    var deferred = deferMe(dm.getGroups);
    if (sid === undefined) { sid = 0; }
    var method = 'GET';
    var url = "get_groups";
    var params = {sid: sid};

    var succ = function (data) {
      dm.groups = data.groups;
      deriveAdditionalGroupsData();
      deferred.resolve(dm.groups);
    };

    var err = function () {
      dm.groups = undefined;
      deferred.resolve(dm.groups);
    };

    return promiseThat(dm.getGroups, method, url, params, 'groups', succ, err);
  };


  dm.getTreeMap = function (onSucc) {
    var deferred = deferMe(dm.getTreeMap);
    if (dm.getTreeMap) {
      onSucc(dm.getTreeMap);
      deferred.resolve(dm.getTreeMap);
    }
    var method = 'GET';
    var url = "API/tree_map";
    var params = {};
    /* istanbul ignore next */
    var succ = function (data) {
      onSucc(data);
      dm.treeMap = data.treeMap;
      deferred.resolve(dm.getTreeMap);
    };
    /* istanbul ignore next */
    var err = function () {
      dm.getTreeMap = undefined;
      deferred.resolve(dm.getTreeMap);
    };

    return promiseThat(dm.getTreeMap, method, url, params, 'treeMap', succ, err);
  };


  dm.getPins = function () {
    var deferred = deferMe(dm.getPins);
    var method = 'GET';
    var url = "/API/get_pins";
    var params = {
      company_id: COMPANY_ID
    };
    /* istanbul ignore next */
    var succ = function (data) {
      dm.pins = data;
      deferred.resolve(dm.pins);
    };
    /* istanbul ignore next */
    var err = function () {
      dm.pins = undefined;
      deferred.resolve(dm.pins);
    };

    return promiseThat(dm.getPins, method, url, params, 'pins', succ, err);
  };

  dm.deletePinOnServer = function (pid) {
    var method = 'POST';
    var url = '/API/delete_pins';
    var params = {
      id: pid
    };
    var succ = function (data) {
      removePrestFromPinList(pid);
      unused(data);
    };
    var err = function () {
      unused();
    };
    ajaxService.sendMsg(method, url, params, succ, err);
  };

  dm.updatePinNameOnServer = function (pin) {
    var method = 'POST';
    var url = '/API/rename';
    var params = {
      name: pin.name,
      id: pin.id
    };
    var succ = function (data) {
      dm.changePresetName(pin.id, pin.name);
      unused(data);
    };
    var err = function () {
      unused();
    };
    ajaxService.sendMsg(method, url, params, succ, err);
  };

  dm.getSnapshots = function () {
    var deferred = deferMe(dm.getSnapshots);
    var method = 'GET';
    var url = "get_snapshots";
    var params = {};

    var succ = function (data) {
      _.each(data.snapshots, function (snapshot) {
        snapshot.date = new Date(snapshot.date);
      });
      dm.snapshots = data.snapshots;
      deferred.resolve(dm.snapshots);
    };

    var err = function () {
      dm.snapshots = undefined;
      deferred.resolve(dm.snapshots);
    };

    return promiseThat(dm.getSnapshots, method, url, params, 'snapshots', succ, err);
  };

  dm.getFormalStructure = function (sid) {
    if (sid === undefined) { sid = 0; }
    var deferred = deferMe(dm.getFormalStructure);
    var method = 'GET';
    var url = "get_formal_structure";
    var params = {sid: sid};

    var succ = function (data) {
      dm.formal_structure = data.formal_structure;
      deferred.resolve(dm.formal_structure);
    };

    var err = function () {
      dm.formal_structure = undefined;
      deferred.resolve(dm.formal_structure);
    };

    return promiseThat(dm.getFormalStructure, method, url, params, 'formal_structure', succ, err);
  };

  dm.getGroupMeasures = function (group_id, reset) {
    if (reset) {
      dm.group_measures = undefined;
    }
    var callback;
    var deferred = deferMe(dm.getGroupMeasures);
    var acc_res = [];
    var method = 'GET';
    var url = '/API/get_group_measures';
    var callbackBuilder = function () {
      return function (data) {
        _.each(data, function (metric) {
          acc_res.push(metric);
        });
        acc_res = _.sortBy(acc_res, function (metric) {
          return metric.graph_data.measure_name.toLowerCase();
        });
        dm.group_measures = acc_res;
        deferred.resolve(dm.group_measures);
      };
    };
    callback = callbackBuilder();
    return promiseThat(dm.getGroupMeasures, method, url, {gid: group_id}, 'group_measures', callback, callback);
  };

  dm.getAnalyzeTree = function () {
    var deferred = $q.defer();
    var method = 'POST';
    var url = '/API/cds_show_network_and_metric_names';
    var params = {
      cid: COMPANY_ID
    };
    if (dm.tab_tree) {
      deferred.resolve(dm.tab_tree);
      return deferred.promise;
    }

    var succ = function (response) {
      dm.tab_tree = response.data;
      deferred.resolve(response.data);
    };
    var err = function () {
      deferred.reject();
    };
    var promise = ajaxService.getPromise(method, url, params);
    promise.then(succ, err);
    return deferred.promise;
  };

  dm.getAnalyze = function (group_id, pin_id, sid, overlay_entity) {
    var cacheSize = 5;
    var deferred = $q.defer();
    var method = 'GET';
    var url = '/API/cds_get_analyze_data';

    var params = {
      cid: COMPANY_ID,
      pid: pin_id,
      sid: sid,
      gid: group_id
    };

    if (overlay_entity) {
      if (overlay_entity.type === 'group') {
        params.oegid = overlay_entity.id;
      } else {
        params.oeid = overlay_entity.id;
      }
    }

    var cache_key = (JSON.stringify(params).replace(/\"/g, ""));

    var callback = function (response) {
      var data = response.data;
      var acc_res = {
        metrics:  [],
        networks: []
      };
      _.each(data.measuers, function (measure) {
        acc_res.metrics.push(measure);
      });

      acc_res.metrics = _.sortBy(acc_res.metrics, function (measure) {
        return measure.measure_name.toLowerCase();
      });

      _.each(data.networks, function (measure) {
        acc_res.networks.push(measure);
      });

      acc_res.networks = _.sortBy(acc_res.networks, function (network) {
        return network.name.toLowerCase();
      });

      dm.putValueInCache(cds_get_analyze_data_cache, cache_key, acc_res);
      deferred.resolve(acc_res);
    };

    var errorCallback = function() {
      console.log("Error in response for getAnalyze");
    };

    if (!cds_get_analyze_data_cache) {   //init the cache
      cds_get_analyze_data_cache = dm.createCache('cds_get_analyze_data_cache', cacheSize);
    }

    var cached_value = dm.getValueFromCache(cds_get_analyze_data_cache, cache_key);
    if(cached_value) {    //check if data is in cache
        deferred.resolve(cached_value);
        return deferred.promise;
    }

    var promise = ajaxService.getPromise(method, url, params);
    promise.then(callback, errorCallback);
    return deferred.promise;
  };

  dm.createCache = function (cacheName, size) {
    return $cacheFactory(cacheName, { capacity : size });
  };

  dm.getValueFromCache = function(cacheObject, cacheKey) {
    return cacheObject.get(cacheKey);
  };

  dm.putValueInCache = function(cacheObject, key, value) {
    return cacheObject.put(key, value);
  };

  dm.getEmployeeScoresById = function (id) {
    dm.employee_scores = null;
    var deferred = deferMe(dm.getEmployeeScoresById);
    var callbackBuilder = function () {
      return function (data) {
        dm.employee_scores = _.sortBy(data, function (measure) {
          return measure.name.toLowerCase();
        });
        deferred.resolve(dm.employee_scores);
      };
    };
    var callback = callbackBuilder();
    return promiseThat(dm.getEmployeeScoresById, 'GET', 'API/get_employee_measures', { employee_id: id }, 'employee_scores', callback, callback);
  };

  dm.getFlaggedEmployees = function (company_metric_id, group_id, sid, reset) {
    if (reset) {
      dm.flagged_employees = null;
    }
    var callback;
    var deferred = deferMe(dm.getFlaggedEmployees);
    var method = 'GET';
    var url = "API/get_cds_flagged_employees";
    /* istanbul ignore next */
    var callbackBuilder = function () {
      return function (data) {
        dm.flagged_employees = data.flagged_employees;
        deferred.resolve(dm.flagged_employees);
      };
    };
    var params;
    callback = callbackBuilder();
    params = {
      cid: COMPANY_ID,
      gid: group_id,
      sid: sid,
      company_metric_id: company_metric_id
    };
    var err = function () {
      dm.flagged_employees = undefined;
      deferred.resolve(dm.flagged_employees);
    };

    return promiseThat(dm.getFlaggedEmployees, method, url, params, 'flagged_employees', callback, err);
  };

  dm.getFlags = function (group_id, pin_id, reset) {
    if (reset) {
      dm.flags = null;
    }
    var flag_types = [];
    var callback;
    var deferred = deferMe(dm.getFlags);
    var acc_res = [];
    var method = 'GET';
    var url = "API/get_cds_flag_data";

    var callbackBuilder = function () {
      return function (data) {
        _.each(data, function (flag) {
          acc_res.push(flag);
        });
        acc_res = _.sortBy(acc_res, function (flags) {
          return flags.graph_data.measure_name.toLowerCase();
        });
        dm.flags = acc_res;
        deferred.resolve(dm.flags);
      };
    };
    var params;
    callback = callbackBuilder();
    params = {
      cid: COMPANY_ID,
      pid: pin_id,
      gid: group_id,
      measure_types: flag_types
    };
    var err = function () {
      dm.flags = undefined;
      deferred.resolve(dm.flags);
    };

    return promiseThat(dm.getFlags, method, url, params, 'flags', callback, err);
  };

  dm.runPrecalculate = function(gid, cmid) {
    var deferred = deferMe(dm.runPrecalculate);
    var method = 'GET';
    var url = 'algorithms_test/precalculate';
    var params = {
      gid: gid,
      cmid: cmid
    };

    var succ = function (data) {
      deferred.resolve(data);
    };

    var err = function (errormsg) {
      deferred.resolve("error " + errormsg);
    };
    return promiseThat(dm.runPrecalculate, method, url, params, 'run-precalculate', succ, err);
  };

  dm.addEmailRelation = function(femp, temp, mid, ftype, ttype) {
    var deferred = deferMe(dm.addEmailRelation);
    var method = 'POST';
    var url = "/API/add_email_relation";
    var params = {
      from_employee: femp,
      to_employee: temp,
      message_id: mid,
      from_type: ftype,
      to_type: ttype
    };
    var succ = function (data) {
      deferred.resolve(data);
    };
    var err = function (errormsg) {
      deferred.resolve("error " + errormsg);
    };
    return promiseThat(dm.addEmailRelation, method, url, params, 'add_email_relation', succ, err);
  };

  dm.deleteEmailRelation = function(relid) {
    var deferred = deferMe(dm.deleteEmailRelation);
    var method = 'POST';
    var url = "/API/delete_email_relation";
    var params = {
      id: relid,
    };
    var succ = function () {
      deferred.resolve('ok');
    };
    var err = function (errormsg) {
      deferred.resolve("error " + errormsg);
    };
    return promiseThat(dm.deleteEmailRelation, method, url, params, 'delete_email_relation', succ, err);
  };
  dm.getEmailsNetwork = function(gid, fromEmailFilter, sid) {
    if (sid === undefined) { sid = 0; }
    var deferred = deferMe(dm.getEmailsNetwork);
    var method = 'GET';
    var url = "API/get_emails_network";

    var callback = function (emails_network) {
        deferred.resolve(emails_network);
    };

    if (gid === null || gid === undefined) { gid = -1; }
    var params = {
      cid: COMPANY_ID,
      gid: gid,
      sid: sid,
      from_email_filter: fromEmailFilter
    };
    var err = function () {
      dm.emails_network = undefined;
      deferred.resolve(dm.emails_network);
    };

    return promiseThat(dm.getEmailsNetwork, method, url, params, 'emails_network', callback, err);
  };

  dm.getWordcloud = function (group_id, pin_id, reset) {
    if (reset) {
      dm.wordcloud = null;
    }
    var callback;
    var deferred = deferMe(dm.getWordcloud);
    var method = 'GET';
    var url = "API/get_wordcloud";
    /* istanbul ignore next */
    var callbackBuilder = function () {
      return function (data) {
        dm.wordcloud = data;
        deferred.resolve(dm.wordcloud);
      };
    };
    var params;
    callback = callbackBuilder();
    params = {
      cid: COMPANY_ID,
      pid: pin_id,
      gid: group_id,
    };
    var err = function () {
      dm.flags = undefined;
      deferred.resolve(dm.wordcloud);
    };

    return promiseThat(dm.getWordcloud, method, url, params, 'wordcloud', callback, err);
  };

  dm.getGauges = function (group_id, pin_id, reset_after_receive) {
    if (!reset_after_receive) {
      dm.gauges = null;
    }
    var gauge_types = [];
    var callback;
    var deferred = deferMe(dm.getGauges);
    var acc_res = [];
    var method = 'GET';
    var url = "API/get_cds_gauge_data";
    /* istanbul ignore next */
    var callbackBuilder = function () {
      return function (data) {
        dm.gauges = null;
        _.each(data, function (gauge) {
          gauge.rate = parseFloat(gauge.rate);
          acc_res.push(gauge);
        });
        acc_res = _.sortBy(acc_res, function (gauges) {
          return gauges.graph_data.measure_name.toLowerCase();
        });
        dm.gauges = acc_res;
        deferred.resolve(dm.gauges);
      };
    };
    var params;
    callback = callbackBuilder();
    params = {
      cid: COMPANY_ID,
      pid: pin_id,
      gid: group_id,
      measure_types: gauge_types
    };
    var err = function () {
      console.log("++++++ ERROR Getting Gauges ++++++");
      dm.gauges = undefined;
      deferred.resolve(dm.gauges);
    };
    return promiseThat(dm.getGauges, method, url, params, 'gauges', callback, err, reset_after_receive);
  };

  var populateTopLevelGaugeParams = function(gauge_list_element, server_data) {
    /* istanbul ignore next */
    gauge_list_element.rate = server_data.rate;
    gauge_list_element.min_range = server_data.min_range;
    gauge_list_element.max_range = server_data.max_range;
    gauge_list_element.min_range_wanted = server_data.min_range_wanted;
    gauge_list_element.max_range_wanted = server_data.max_range_wanted;
    gauge_list_element.background_color = server_data.background_color;
  };

  dm.getTopLevelGauges = function (gauge_list, reset) {
    if (reset) {
      dm.gauges = null;
    }
    var callback;
    var deferred = deferMe(dm.getTopLevelGauges);
    var acc_res = [];
    var method = 'GET';
    var url = "API/get_cds_gauge_data";
    /* istanbul ignore next */
    var callbackBuilder = function () {

      return function (data) {
        _.each(data, function (gauge) {
          if (gauge.algorithm_id === 501) {
            populateTopLevelGaugeParams(gauge_list[1], gauge);
          } else if (gauge.algorithm_id === 502) {
            populateTopLevelGaugeParams(gauge_list[0], gauge);
          } else if (gauge.algorithm_id === 503) {
            populateTopLevelGaugeParams(gauge_list[2], gauge);
          } else if (gauge.algorithm_id === 504) {
            populateTopLevelGaugeParams(gauge_list[3], gauge);
          } else {
            console.log("Unknown top level algorithm: ", data.algorithm_id);
          }
        });

        dm.gauges = acc_res;
        deferred.resolve(dm.gauges);
      };
    };

    var params;
    callback = callbackBuilder();
    params = {
      cid: COMPANY_ID,
      type: 'level1'
    };
    var err = function () {
      console.log("++++++ ERROR getting top level gauges ++++++");
      dm.gauges = undefined;
      deferred.resolve(dm.gauges);
    };
    return promiseThat(dm.getTopLevelGauges, method, url, params, 'gauges', callback, err);
  };

  dm.getMeasures = function (group_id, pin_id, reset) {
    if (!reset) {
      dm.mesures = null;
    }
    var measure_types = [];
    var callback;
    var deferred = deferMe(dm.getMeasures);
    var acc_res = [];
    var method = 'GET';
    var url = "API/get_cds_measure_data";
    /* istanbul ignore next */
    var callbackBuilder = function () {
      return function (data) {
        dm.mesures = null;
        _.each(data, function (measure, name) {
          measure.name = name;
          acc_res.push(measure);
        });
        acc_res = _.sortBy(acc_res, function (measure) {
          return measure.graph_data.measure_name.toLowerCase();
        });
        dm.mesures = acc_res;
        addNetworkToMeasures(dm.mesures);
        deferred.resolve(dm.mesures);
      };
    };
    var params;
    callback = callbackBuilder(measure_types);
    params = {
      cid: COMPANY_ID,
      pid: pin_id,
      gid: group_id,
      measure_types: measure_types
    };

    return promiseThat(dm.getMeasures, method, url, params, 'measures', callback, callback, reset);
  };

  var callback_succ_arr = [];
  var callback_err_arr = [];
  function clearCallBacks() {
    callback_succ_arr = [];
    callback_err_arr = [];
  }

  dm.getCompanyStatistics = function (reset, onSucc, onError) {
    unused(onError);

    if (reset) {
      dm.company_statistics  = null;
    } else {
      if (dm.company_statistics) {
        onSucc(dm.company_statistics);
      }
    }
    var method = 'GET';
    var url = '/API/get_company_statistics';
    var succ = function (response) {
      dm.company_statistics = response.data;
      _.each(callback_succ_arr, function (onSucc) { if (onSucc) { onSucc(response.data); } });
      clearCallBacks();
    };
    var err = function () {
      _.each(callback_err_arr, function (onError) { if (onError) { onError(); } });
      clearCallBacks();
      unused();
    };

    var params;
    // callback = callbackBuilder();
    params = {'sid': null};
    callback_succ_arr.push(onSucc);
    if (callback_succ_arr.length > 1) { return; }
    var promise = ajaxService.getPromise(method, url, params);
    promise.then(succ, err);
    // return promiseThat(dm.getCompanyStatistics, method, url, params, 'company_statistics', callback, callback);
  };

  dm.getMostCommunicationVolumeDiffBetweenDyads = function (gid, sid) {
    dm.top_dyads = undefined;
    var deferred = deferMe(dm.getMostCommunicationVolumeDiffBetweenDyads);
    var params;
    var method = 'GET';
    var url = 'API/dyads_with_the_biggest_diff';
    var succ = function (data) {
      dm.top_dyads = data;
      deferred.resolve(dm.top_dyads);
    };
    /* istanbul ignore next */
    var err = function () {
      dm.top_dyads = undefined;
      deferred.resolve(dm.top_dyads);
    };
    params = { gid: gid, sid: sid};
    return promiseThat(dm.getMostCommunicationVolumeDiffBetweenDyads, method, url, params, 'top_dyads', succ, err);
  };

  dm.getCollaborationDynamicsPie = function (gid) {
    dm.collaboration_dynamics_pie = undefined;
    var deferred = deferMe(dm.getCollaborationDynamicsPie);
    var params;
    var method = 'GET';
    var url = 'API/collaboration_dynamics_pie';
    var succ = function (data) {
      dm.collaboration_dynamics_pie = data;
      deferred.resolve(dm.collaboration_dynamics_pie);
    };
    /* istanbul ignore next */
    var err = function () {
      dm.collaboration_dynamics_pie = undefined;
      deferred.resolve(dm.collaboration_dynamics_pie);
    };
    params = { gid: gid};
    return promiseThat(dm.getCollaborationDynamicsPie, method, url, params, 'collaboration_dynamics_pie', succ, err);
  };

  dm.getNewPlaySession = function (measure_id, network_id, group_id, pin_id, reset) {
    if (reset) {
      dm.play_session_data = null;
    }
    var callback;
    var deferred = deferMe(dm.getNewPlaySession);
    var method = 'GET';
    var url = '/API/get_play_session';
    /* istanbul ignore next */
    var callbackBuilder = function () {
      return function (acc_res) {
        dm.play_session_data = acc_res;
        deferred.resolve(dm.play_session_data);
      };
    };
    var params;
    callback = callbackBuilder();
    params = {
      measure_id: measure_id,
      network_id: network_id,
      gid: group_id,
      pid: pin_id
    };
    return promiseThat(dm.getNewPlaySession, method, url, params, 'play_session_data', callback, callback);
  };

  dm.getExternalDataList = function (reset) {
    if (reset) {
      dm.external_data_list = null;
    }
    var callback;
    var deferred = deferMe(dm.getExternalDataList);
    var method = 'GET';
    var url = '/API/get_external_data';
    /* istanbul ignore next */
    var callbackBuilder = function () {
      return function (acc_res) {
        dm.external_data_list = acc_res;
        convertTheScoreToFloat(dm.external_data_list);
        deferred.resolve(dm.external_data_list);
      };
    };
    var params;
    callback = callbackBuilder();
    params = null;
    return promiseThat(dm.getExternalDataList, method, url, params, 'external_data_list', callback, callback);

  };

  // _TODO should move out of dm??
  dm.editExternalDataMetric = function (external_data_list, reset) {
    if (reset) {
      dm.external_data_list = null;
    }
    var deferred = deferMe(dm.editExternalDataMetric);
    var method = 'POST';
    var url = "setting/set_external_data";
    var params = external_data_list;
    /* istanbul ignore next */
    var succ = function (data) {
      dm.external_data_list = data;
      deferred.resolve(dm.external_data_list);
    };
    /* istanbul ignore next */
    var err = function () {
      dm.external_data_list = undefined;
      deferred.resolve(dm.external_data_list);
    };
    return promiseThat(dm.editExternalDataMetric, method, url, params, 'external_data_list', succ, err);
  };

  dm.resendAllQuestionnaire = function (q_id, reset) {
    if (reset) {
      dm.resend_all_status = null;
    }
    var deferred = deferMe(dm.resendAllQuestionnaire);
    var method = 'POST';
    var url = "questionnaire/send_questionnaire_ajax";
    var params = { questionnaire_id: q_id, send_only_to_unstarted: true, sender_type: 'email' };
    var succ = function (data) {
      dm.resend_all_status = data;
      deferred.resolve(dm.resend_all_status);
    };
    /* istanbul ignore next */
    var err = function (data) {
      dm.resend_all_status = data;
      deferred.resolve(dm.resend_all_status);
    };
    // ajaxService.sendMsg(method, url, params, succ, err);
    return promiseThat(dm.resendAllQuestionnaire, method, url, params, 'resend_all_status', succ, err);
  };

  dm.getAnalyseFlags = function (gid, pid, reset) {
    if (reset) {
      dm.analyse_flags = undefined;
    }
    var deferred = deferMe(dm.getAnalyseFlags);
    var method = 'GET';
    var url = "/API/analyze_friendship";
    var params = {
      cid: COMPANY_ID,
      pid: pid,
      gid: gid
    };
    /* istanbul ignore next */
    var succ = function (data) {
      deferred.resolve(data);
    };
    /* istanbul ignore next */
    var err = function () {
      deferred.resolve();
    };

    return promiseThat(dm.getAnalyseFlags, method, url, params, 'analyse_flags', succ, err);
  };


  dm.getNetworksAndMetricForCompany = function () {
    var deferred = deferMe(dm.getNetworksAndMetricForCompany);
    var method = 'GET';
    var url = "/API/get_network_and_metric_names";
    var params = {
      cid: COMPANY_ID,
    };
    /* istanbul ignore next */
    var succ = function (data) {
      deferred.resolve(data);
    };
    /* istanbul ignore next */
    var err = function () {
      deferred.resolve();
    };

    return promiseThat(dm.getNetworksAndMetricForCompany, method, url, params, 'network_with_metric_name', succ, err);
  };

  dm.getAnalyseSocialMeasure = function (gid, pid, reset) {
    if (reset) {
      dm.analyse_social = undefined;
    }
    var deferred = deferMe(dm.getAnalyseSocialMeasure);
    var method = 'GET';
    var url = '/API/analyze_social';
    var params = {
      cid: COMPANY_ID,
      pid: pid,
      gid: gid
    };
    /* istanbul ignore next */
    var succ = function (data) {
      deferred.resolve(data);
    };
    /* istanbul ignore next */
    var err = function () {
      deferred.resolve();
    };

    return promiseThat(dm.getAnalyseSocialMeasure, method, url, params, 'analyse_social', succ, err);
  };

  dm.getEmployeesPin = function (pid) {
    dm.employees_pin = undefined;
    var deferred = deferMe(dm.getEmployeesPin);
    var method = 'GET';
    var url = "/API/get_employess_pin";
    var params = { pid: pid };
    /* istanbul ignore next */
    var succ = function (data) {
      dm.employees_pin = data;
      deferred.resolve(dm.employees_pin);
    };
    /* istanbul ignore next */
    var err = function () {
      dm.employees_pin = undefined;
      deferred.resolve(dm.employees_pin);
      //__TODO add to error log
    };

    return promiseThat(dm.getEmployeesPin, method, url, params, 'employees_pin', succ, err);
  };

  // _TODO should move out of dm
  dm.getPieChartData = function (id) {
    dm.employee_relations = undefined;
    var deferred = deferMe(dm.getPieChartData);
    var method = 'GET';
    var url = "/API/get_directory_data";
    var params = { eid: id };
    /* istanbul ignore next */
    var succ = function (data) {
      dm.employee_relations = data;
      var data_to_pie_chart = createEmployeesRelationWeight(id);
      deferred.resolve(data_to_pie_chart);
    };
    /* istanbul ignore next */
    var err = function () {
      dm.employee_relations = undefined;
      deferred.resolve(dm.employee_relations);
      //__TODO add to error log
    };

    return promiseThat(dm.getPieChartData, method, url, params, 'employee_relations', succ, err);
  };

  dm.getSnapshotList = function () {
    var deferred = $q.defer();
    var method = 'GET';
    var url = '/API/get_snapshot_list';
    var params = null;

    if (dm.snapshot_list) {
      deferred.resolve(dm.snapshot_list);
      return deferred.promise;
    }

    var succ = function (data) {
      dm.snapshot_list = data;
      deferred.resolve(dm.snapshot_list);
    };
    var err = function () {
      deferred.reject();
    };
    ajaxService.sendMsg(method, url, params, succ, err);
    return $q.when(dm.snapshot_list || deferred.promise);
  };

  // _TODO do we need this?
  dm.getManagers = function () {
    var deferred = deferMe(dm.getManagers);
    var method = 'GET';
    var url = "get_managers";
    var params = null;
    /* istanbul ignore next */
    var succ = function (data) {
      dm.managers = data.managers;
      deferred.resolve(dm.managers);
    };
    /* istanbul ignore next */
    var err = function () {
      dm.managers = undefined;
      deferred.resolve(dm.managers);
    };

    return promiseThat(dm.getManagers, method, url, params, 'managers', succ, err);
  };

  dm.getColors = function () {
    var deferred = deferMe(dm.getColors);
    var method = 'GET';
    var url = "/get_colors";
    var params = null;
    /* istanbul ignore next */
    var succ = function (data) {
      dm.colors = data;
      deferred.resolve(dm.colors);
    };
    /* istanbul ignore next */
    var err = function () {
      dm.colors = undefined;
      deferred.resolve(dm.colors);
    };

    return promiseThat(dm.getColors, method, url, params, 'colors', succ, err);
  };

  // _TODO move out of dm
  dm.createPreset = function (name, definition, id, status) {
    var deferred = deferMe(dm.createPreset);
    dm.preset_sucss = undefined;
    var method = 'POST';
    var url = "/create_preset";
    var params = {
      action_button: status,
      id: id,
      name: name,
      definition: definition
    };
    /* istanbul ignore next */
    var succ = function (data) {
      _.remove(dm.pins.drafts, function (pin) {
        return pin.id === id;
      });
      if (status === SAVED_AS_DRAFT) {
        dm.pins.drafts.push(data.preset);
      } else {
        dm.pins.in_progress.push(data.preset);
      }
      deferred.resolve(dm.preset_sucss);
    };
    /* istanbul ignore next */
    var err = function () {
      dm.preset_sucss = undefined;
      deferred.resolve(dm.preset_sucss);
    };
    return promiseThat(dm.createPreset, method, url, params, 'preset_sucss', succ, err);
  };


  /**************  available only after models were loaded **************/

  // _TODO all those functions should be at a different module

  dm.getColorsByName = function (name_of_group_by, attr_name) {
    var color;
    if (name_of_group_by === 'formal_structure' || name_of_group_by === 'group_id') {
      color = dm.colors.g_id[attr_name];
    } else if (name_of_group_by === 'manager_id') {
      color = dm.colors.manager_id[attr_name];
    } else {
      color = dm.colors.attributes[attr_name];
    }
    return color;
  };

  dm.getEmployeesByIds = function (idsArr) {
    return _.map(idsArr, function (id) {
      return _.find(dm.employees, function (e) {
        return e.id === id;
      });
    });
  };

  dm.updateDictionaries = function () {
    deriveAdditionalGroupsData();
    createEmployeesDictionary();
  };

  dm.getBreadCrumbs = function (id, type) {
    var res;
    switch (type) {
    case 'group':
      res = getBreadCrumbsFromGroup(id);
      break;
    case 'pin':
      res = getBreadCrumbsFromPin(id);
      break;
    default:
      return res;
    }
    return res;
  };

  dm.getDefaultGroupId = function () {
    var company = dm.formal_structure[0];
    return company.group_id;
  };
  dm.getGroupByHeight = function (levels) {
    var res = [];
    var groups = _.filter(dm.groups, function (group) {
      return (group.level === levels);
    });
    _.each(groups, function (group) {
      res.push(group.id);
    });
    return res;
  };

  //_TODO should be cached, prefer using reactive
  dm.getSearchList = function () {
    return function () {
      var res = [];
      _.each(dm.groups, function (g) {
        res.push({
          id: g.id,
          name: g.name,
          type: 'group'
        });
      });
      _.each(dm.pins.active, function (p) {
        res.push({
          id: p.id,
          name: p.name,
          type: 'pin'
        });
      });
      return res;
    };
  };
  //_TODO should be cached, prefer using reactive
  dm.getAnalyzeSearch = function () {
    return function () {
      var res = [];
      _.each(dm.groups, function (g) {
        res.push({
          id: g.id,
          name: g.name,
          type: 'group'
        });
      });
      _.each(dm.employees, function (e) {
        res.push({
          id: e.id,
          name: e.first_name + ' ' + e.last_name,
          type: 'emp'
        });
      });
      return res;
    };
  };

  dm.getGroupOrIndividualView = function () {
    var deferred = deferMe(dm.getGroupOrIndividualView);
    var method = 'GET';
    var url = "setting/get_group_individual_state";
    var params = {};
    /* istanbul ignore next */
    var succ = function (data) {
      dm.bottom_up_view = JSON.parse(data.state);
      deferred.resolve(dm.bottom_up_view);
    };
    /* istanbul ignore next */
    var err = function () {
      dm.bottom_up_view = undefined;
      deferred.resolve(dm.bottom_up_view);
    };
    return promiseThat(dm.getGroupOrIndividualView, method, url, params, 'bottom_up_view', succ, err);
  };

  dm.setGroupOrIndividualView = function (bottom_up_view) {
    var deferred = deferMe(dm.setGroupOrIndividualView);
    var method = 'POST';
    var url = "setting/save_group_individual_state";
    var params = { state: bottom_up_view };
    /* istanbul ignore next */
    var succ = function (data) {
      if (!data.success) { console.log('problem in update'); }
      dm.bottom_up_view =  JSON.parse(data.state);
      deferred.resolve(dm.bottom_up_view);
    };
    /* istanbul ignore next */
    var err = function () {
      deferred.resolve();
    };
    return promiseThat(dm.setGroupOrIndividualView, method, url, params, 'bottom_up_view_1', succ, err);
  };

  dm.freezQuestionnaire = function() {
    var deferred = $q.defer();
    var method = 'GET';
    var url = "questionnaire/capture_snapshot";
    var succ = function (res) {
      deferred.resolve(res.data);
    };

    var err = function (e) {
      console.log("Error in freezQuestionnaire(): ", e);
      deferred.resolve(dm.ui_levels);
    };

    var promise = ajaxService.getPromise(method, url);
    promise.then(succ, err);
    return deferred.promise;
  };

  dm.getFreezQuestionnaireStatus = function() {
    var deferred = $q.defer();
    var method = 'GET';
    var url = "questionnaire/get_questionnaire_state";
    var succ = function (res) {
      deferred.resolve(res.data.questionnaire_status);
    };

    var err = function (e) {
      console.log("Error in getFreezQuestionnaireStatus: ", e);
      deferred.resolve(dm.ui_levels);
    };

    var promise = ajaxService.getPromise(method, url);
    promise.then(succ, err);
    return deferred.promise;
  };

  dm.getUiLevels = function () {
    var deferred = $q.defer();
    var method = 'GET';
    var url = "API/get_ui_levels";

    var params = {
      company_id: COMPANY_ID
    };

    var succ = function (res) {
      dm.ui_levels = res.data.children;
      deferred.resolve(dm.ui_levels);
    };

    var err = function () {
      dm.ui_levels = undefined;
      deferred.resolve(dm.ui_levels);
    };

    var promise = ajaxService.getPromise(method, url, params);
    promise.then(succ, err);
    return deferred.promise;
  };

  dm.getUiLevel = function (level) {
    return dm.ui_levels[level].children;
  };

  dm.passwordChangedSuccessfully = false;

  dm.init = function () {
    dm.getUiLevels().then(function (response) {
      dm.ui_levels = response.children;
    });
    dm.getColors();
    dm.getFormalStructure();
  };

  return dm;
});
