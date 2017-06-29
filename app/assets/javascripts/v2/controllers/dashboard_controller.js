/*globals angular , unused, _, setTimeout, window , document, alert*/

angular.module('workships').controller('dashboardController', function ($interval, $scope, sidebarMediator, tabService, pleaseWaitService, analyzeMediator) {
  'use strict';

  $scope.$parent.restart = function () {
    $scope.init();
  };

  $scope.$on('resize', function () {
    return window.innerWidth;
  }, function (value) {
    $scope.move_stats = false;
    $scope.how_much_move_stats = 1280 - value;
    if (value <= 1279) {
      $scope.move_stats = true;
    }
    $scope.cancel_right = false;
    if (value > 1279 && value < 1345) {
      $scope.cancel_right = true;
    }
    if (value > 1024) {
      var new_size = (value - 1024) / 72;
      $scope.design_size_of_gauges = 72 + new_size;
    }
  });

  $scope.keepDistance = function () {
    if ($scope.move_stats === true) {
      var val = 0 - $scope.how_much_move_stats;
      return {'right': val.toString() + 'px'};
    }
    if ($scope.cancel_right === true) {
      return {'right': '12px'};
    }
    return {'': ''};
  };

  $scope.keepHeight = function () {
    if ($scope.cancel_right === true) {
      return {'width': (1250 - (1344 - window.innerWidth)) + 'px'};
    }
    return {'width': '99%'};
  };

  function setCommDynamics(res) {
    if (res.data) {
      $scope.comm_dynamics = res.data;
    } else {
      $scope.comm_dynamics = [];
      $scope.comm_dynamics_msg = res.msg;
    }
  }

  $scope.init = function () {
    pleaseWaitService.on();
    tabService.stopSpinning = false;
    $scope.design_size_of_gauges = 72;
    $scope.gauge_list = [{
      min_range: 0,
      max_range: 100,
      min_range_wanted: 20,
      max_range_wanted: 50,
      rate: 30,
      radius: $scope.design_size_of_gauges,
      title: 'Workflow',
      background_color: 'rgba(248, 152, 56, 0.16)',
      wanted_area_color: 'rgb(248, 152, 56)'
    }, {
      min_range: 0,
      max_range: 100,
      min_range_wanted: 20,
      max_range_wanted: 60,
      rate: 0,
      radius: $scope.design_size_of_gauges,
      title: 'Collaboration',
      background_color: 'rgba(144,88,232,0.16)',
      wanted_area_color: 'rgb(144,88,232)'
    }, {
      min_range: 0,
      max_range: 100,
      min_range_wanted: 0,
      max_range_wanted: 32,
      rate: 40,
      radius: $scope.design_size_of_gauges,
      title: 'Productivity',
      background_color: 'rgba(237,30,121,0.16)',
      wanted_area_color: 'rgb(237,30,121)'
    }, {
      min_range: 0,
      max_range: 100,
      min_range_wanted: 0,
      max_range_wanted: 49,
      rate: 20,
      radius: $scope.design_size_of_gauges,
      title: 'Top Talent',
      background_color: 'rgba(122,201,65, 0.16)',
      wanted_area_color: 'rgb(122,201,65)'
    }];

    $scope.sidebar = sidebarMediator;
    $scope.miniHeader = tabService.showMiniHeader;

    //////////////////////////////////////////////////////////////////
    // These scope variables are all related to the measure debugger
    //////////////////////////////////////////////////////////////////
    $scope.selectedGroup    = undefined;
    $scope.selectedSnapshot = undefined;
    $scope.snapshots        = undefined;
    $scope.measures         = [];
    $scope.selectedMeasure  = undefined;
    $scope.scores           = undefined;
    $scope.displayAddRowModal = false;
    $scope.messageId        = Math.random().toString(36).replace(/[^a-z]+/g, '').substr(0, 8).toUpperCase();
    $scope.fromFilter       = '';

    $scope.data_model.getSnapshots().then(function(snapshots) {
      $scope.snapshots = snapshots;
      $scope.selectedSnapshot = $scope.snapshots[0].id;
      console.log("selected snapshot id: ", $scope.selectedSnapshot );

      $scope.data_model.getGroups($scope.selectedSnapshot).then(function(groups) {
        $scope.groups = groups;
      });

      $scope.data_model.getEmployees($scope.selectedSnapshot).then(function(emps) {
        $scope.emps = emps;
      });

      $scope.data_model.getEmailsNetwork(-1, '', $scope.selectedSnapshot).then(function(network) {
        $scope.network = network;
      });
    });
  };

  $scope.filterEmailData = function() {
    console.log("In the filter");
    $scope.data_model.getEmailsNetwork($scope.selectedGroup, $scope.fromFilter).then(function(network) {
      $scope.network = network;
    });
  };

  $scope.addEmailConnection = function() {
    $scope.data_model.addEmailRelation(
      $scope.fromEmp,
      $scope.toEmp,
      $scope.messageId,
      $scope.fromType,
      $scope.toType
    ).then(function(rel) {
      $scope.fromEmp = rel.from_employee_id;
      $scope.toEmp = rel.to_employee_id;
      $scope.messageId = rel.message_id;
      $scope.fromType = rel.from_type;
      $scope.toType = rel.to_type;

      $scope.network.push(rel);
    });

    $scope.displayAddRowModal = false;
  };

  var findScoresFromFlag = function(n) {
    return n.ret_list;
  };

  var findScoresFromMeasure = function(n) {
    var sids = Object.keys(n.snapshots);
    sids = _.forEach( sids, function(sid) { return  parseInt(sid,0); });
    var maxsid = Math.max.apply(Math, sids);
    return n.snapshots[maxsid.toString()];
  };

  var updateScoresList = function(n) {
    var measure_type = n.graph_data.type;
    if (measure_type === 'flag') {
      $scope.scores = findScoresFromFlag(n);
    } else if (measure_type === 'measure') {
      $scope.scores = findScoresFromMeasure(n);
    } else {
      console.error("Unrecoginzed measure_type in measure debugger");
    }
  };

  $scope.runPrecalculate = function(group, measure) {
    if (group === undefined || measure === undefined) {
      return alert('Can not run precalculate without group and measure');
    }
    var gid = group.id;
    var cmid = measure.company_metric_id;
    var selectedMeasure = $scope.selectedMeasure;

    pleaseWaitService.on();
    $scope.data_model.runPrecalculate(gid, cmid)
      .then( function() {
        return $scope.data_model.getMeasures(gid, -1, false);
      })
    //.then( function() {
    //    return $scope.data_model.getFlags(gid, -1, false);
    //  })
      .then(function () {
        $scope.measures = $scope.data_model.mesures;
        //var reduced_flags = _.filter($scope.data_model.flags, function(e) {
        //  return e.ret_list.length > 0;
        //});
        //$scope.measures = $scope.measures.concat(reduced_flags);
        $scope.selectedMeasure = selectedMeasure;
        updateScoresList(selectedMeasure);
      });
  };

  $scope.deleteEmailConnection = function(relid) {
    $scope.data_model.deleteEmailRelation(relid);
    _.remove($scope.network, {id: relid});
  };

  $scope.$watch('selectedGroup', function(n,o) {
    if (n === o) { return; }
    $scope.data_model.getMeasures(n.id, -1, false).then(function () {
      $scope.measures = $scope.measures.concat($scope.data_model.mesures);
      console.log("measures after measures: ", $scope.measures);
    });

    //$scope.data_model.getFlags(n.id, -1, false).then(function () {
    //  var reduced_flags = _.filter($scope.data_model.flags, function(e) {
    //    return e.ret_list.length > 0;
    //  });
    //  $scope.measures = $scope.measures.concat(reduced_flags);
    //  console.log("measures after flags: ", $scope.measures);
    //});
  });

  $scope.decodeFromType = function(t) {
    if (t === 1) {
      return "init";
    }
    return "na";
  };

  $scope.decodeToType = function(t) {
    if (t === 1) {
      return "to";
    } else if (t === 2) {
      return "cc";
    } else if (t === 3) {
      return "bcc";
    }
    return "na";
  };

  $scope.openEmailModal = function() {
    console.log("in open email modal");
    $scope.displayAddRowModal = !$scope.displayAddRowModal;
  };

  $scope.$watch('selectedMeasure', function(n,o) {
    if (n === o) { return; }
    if (n === null) { return; }
    updateScoresList(n);
  });

  $scope.findEmployeeName = function(id) {
    var emp = _.find($scope.emps, function(e) { return e.id === id; });
    return emp.first_name + " " + emp.last_name;
  };

  $scope.$watch('tabService.current_tab', function (new_val, old_val) {
    if (new_val === old_val) {
      return;
    }
    if (new_val !== 'Dashboard') {
      $interval.cancel($scope.stats_interval);
    }

    if (old_val === 'Explore') {
      analyzeMediator.saveCurrentChartState();
    }
  });
});
