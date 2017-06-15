/*globals angular , unused, _, alert, $*/
angular.module('workships').controller('graphWidgetController',
  function ($scope, $element, utilService, dataModelService) {
    'use strict';

    var self = this;
    var MONTHS = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];

    var calculateTransform = function (last, curr, width) {
      var HEIGHT = 20;

      var curr_height = curr * HEIGHT;
      var last_height = last * HEIGHT;
      var dy = curr_height - last_height;
      var angle = -Math.atan2(dy, width) * 180 / Math.PI;
      var new_width = Math.sqrt((width * width) + (dy * dy));
      var style = {
        'new_width': new_width,
        scale: angle,
        last_trend_in_size: last_height
      };
      return style;
    };

    var setLineStyle = function (left, right, width) {
      var style = calculateTransform(left, right, width);
      return {
        'transform': "rotate(" + style.scale + "deg)",
        'bottom': style.last_trend_in_size + "px",
        'width': style.new_width + "px"
      };
    };

    var calculateTooltipTransform = function (last, curr) {
      var WIDTH = 58;
      var HEIGHT = 20;
      var curr_height = curr * HEIGHT;
      var last_height = last * HEIGHT;
      var dy = curr_height - last_height;
      var angle = Math.atan2(dy, WIDTH) * 180 / Math.PI;
      return angle;
    };

    $scope.setTooltipStyle = function (last, curr) {
      var left = -1;
      if (last >= curr) {
        left = curr + ((last - curr) / 2);
      } else {
        left = curr - ((curr - last) / 2);
      }
      return {
        'transform': "rotate(" + calculateTooltipTransform(left, curr) + "deg)"
      };
    };

    $scope.setLineStyleLeft = function (last, curr) {
      var left = -1;
      if (last >= curr) {
        left = curr + ((last - curr) / 2);
      } else {
        left = curr - ((curr - last) / 2);
      }
      return setLineStyle(left, curr, 58);
    };

    $scope.setLineStyleRight = function (curr, next) {
      var right = -1;
      if (next >= curr) {
        right = curr + ((next - curr) / 2);
      } else {
        right = curr - ((curr - next) / 2);
      }
      return setLineStyle(curr, right, 59);
    };

    $scope.toSinglePrecision = function (num) {
      if (num) {
        var snum = num.toString();
        var ret = "";
        if (snum.indexOf(".") > -1) {
          ret = snum;
        } else {
          ret = snum + ".0";
        }
        return ret;
      }
    };

    var selectSnapshot = function (date, lsid, csid, lgroupval, cgroupval) {
      $scope.date_selected = date;
      $scope.selected.current_org_avg = cgroupval;
      $scope.selected.prev_org_avg = lgroupval;
      $scope.selected.snapshot_id = csid;
      $scope.selected.prev_snapshot_id = lsid;
      $scope.selected.change_time = Math.random() * 100000;
    };

    var setUpperRightCornerIndications = function (last, prev, upisgood) {
      if (last > prev && upisgood) {
        $scope.rotate = true;
        $scope.trend = 180;
      } else if (last > prev && !upisgood) {
        $scope.rotate = false;
        $scope.trend = 0;
      } else if (last <= prev && upisgood) {
        $scope.rotate = true;
        $scope.trend = 0;
      } else if (last <= prev && !upisgood) {
        $scope.rotate = false;
        $scope.trend = 180;
      }
      $scope.measureData.graph_data.rotate = $scope.rotate;
      $scope.measureData.graph_data.trend = $scope.trend;
    };

    var createEmptyGraphData = function (last_sid) {
      var res = [];
      var last_snapshot = _.where($scope.snapshots, {
        'id': last_sid
      })[0];
      var year = last_snapshot.name.substring(0, 4);
      var week = last_snapshot.name.substring(5, 7);
      var i = 0;
      for (i; i < 12; i++) {
        week++;
        if (week === 53) {
          week = 0;
          year++;
        }
        if (week < 10) {
          week = '0' + String (week);
        }
        res.push({
          "date":  year + "-" + week
        });
      }
      return res;
    };

    /*   var setInitialDatesRange = function (datalen) {
     var curr_range = $scope.dates_range;
     if (curr_range !== undefined) {
       return curr_range;
     }
     return [datalen - $scope.graphsize.number, datalen];
   };
*/

    var fixFirstElement = function (gdata) {
      var f = gdata[0];
      f.lgroup1 = (2 * f.cgroup1) - f.ngroup1;
      f.lgroup2 = (2 * f.cgroup2) - f.ngroup2;
      return gdata;
    };

    var fixLastElement = function (gdata) {
      var l = gdata[gdata.length - 1];
      l.ngroup1 = (2 * l.cgroup1) - l.lgroup1;
      l.ngroup2 = (2 * l.cgroup2) - l.lgroup2;
      return gdata;
    };

    /**
     * Set the left and right indixes that should be displayed. This depends on the length
     * of the dataset, the size of the widget on the screen (which depends on screen width)
     * on whether the change arrives from a next or prev movements (-1,1) or a resize event (0).
     */
    var changeDisplayedRange = function (delta) {
      var max, min = -1;
      var graphsize = $scope.graphsize.number;
      var datalen = $scope.gdata.length;

      // If the widget width is bigger than the datasize
      if (datalen <= graphsize) {
        $scope.dates_range = [0, datalen - 1];
        return;
      }

      // Handling resize
      if (delta === 0) {
        max = $scope.dates_range === undefined ? datalen - 1 : $scope.dates_range[1];
        min = max - graphsize + 1;
        $scope.dates_range = [min, max];
        return;
      }

      // Now handling case when the data size is bigger than the widget width
      min = $scope.dates_range[0] + delta;
      max = -1;
      if (graphsize >= datalen) {
        max = datalen - 1;
      } else {
        if (min + graphsize - 1 <= datalen) {
          max = min + graphsize - 1;
        } else {
          max = datalen;
        }
      }

      // Do not slide right if its the first snapshot
      if (min < 0) {
        return;
      }
      // Do not slide left if max is on the last slot
      if (max >= datalen) {
        return;
      }

      $scope.dates_range = [min, max];
      return;
    };

    self.addScoreFromSnapshot = function (sid, current_group) {
      var res =  current_group;
      if (!sid) {
        return res;
      }
      var snapshot = _.where($scope.score_list, { 'snapshot_id': sid.csnapshotid});
      if (!_.isEmpty(snapshot)) {
        res = snapshot[0].score_normalize;
      }
      return res;
    };

    /* Test data for the function below
          var gdata = [
            { lgroup1: 2, cgroup1: 4, ngroup1: 9, lgroup2: 1, cgroup2: 7, ngroup2: 9, date: 'Jan 2014' },
            { lgroup1: 4, cgroup1: 9, ngroup1: 3, lgroup2: 7, cgroup2: 9, ngroup2: 5, date: 'Feb 2014' },
            { lgroup1: 9, cgroup1: 3.1, ngroup1: 5, lgroup2: 9, cgroup2: 5.0, ngroup2: 6, date: 'Mar 2014' },
            { lgroup1: 3, cgroup1: 5, ngroup1: 4, lgroup2: 5, cgroup2: 6, ngroup2: 7, date: 'Apr 2014' },
            { lgroup1: 5, cgroup1: 4, ngroup1: 9, lgroup2: 6, cgroup2: 7, ngroup2: 9, date: 'Jun 2014' },
            { lgroup1: 4, cgroup1: 9, ngroup1: 3, lgroup2: 7, cgroup2: 9, ngroup2: 5, date: 'Jul 2014' },
            { lgroup1: 9, cgroup1: 3, ngroup1: 5, lgroup2: 9, cgroup2: 5, ngroup2: 6, date: 'Aug 2014' },
            { lgroup1: 3, cgroup1: 5, ngroup1: 4, lgroup2: 5, cgroup2: 6, ngroup2: 7, date: 'Sep 2014' },
            { lgroup1: 5, cgroup1: 4, ngroup1: 4, lgroup2: 6, cgroup2: 7, ngroup2: 4, date: 'Oct 2014' }];
    */
    self.bind_measure_data_and_create_graph = function () {
      var graph_data = $scope.measureData.graph_data;
      $scope.measure_name = graph_data.measure_name;
      // Rebuild the data structure so it'll suit the directive

      var graph_arr = graph_data.data.values.sort(function (a, b) {
        var a_snapshotid = a[0];
        var b_snapshotid = b[0];
        var a_snapshot = _.where($scope.snapshots, {
          'id': a_snapshotid
        })[0];
        var b_snapshot = _.where($scope.snapshots, {
          'id': b_snapshotid
        })[0];
        return a_snapshot.date - b_snapshot.date;
      });
      var gdata1 = _.map(graph_arr, function (val, inx, coll) {
        var ret = {};
        ret.csnapshotid = val[0];
        ret.lsnapshotid = coll[inx - 1] === undefined ? 0 : coll[inx - 1][0];
        ret.lgroup1 = coll[inx - 1] === undefined ? val[1] : coll[inx - 1][1];
        ret.cgroup1 = val[1];
        ret.ngroup1 = coll[inx + 1] === undefined ? val[1] : coll[inx + 1][1];
        ret.lgroup2 = coll[inx - 1] === undefined ? val[2] : coll[inx - 1][2];
        ret.cgroup2 = val[2];
        ret.ngroup2 = coll[inx + 1] === undefined ? val[2]  : coll[inx + 1][2];
        return ret;
      });
      gdata1 = fixFirstElement(gdata1);
      gdata1 = fixLastElement(gdata1);

      // Format the date part
      var gdata = _.map(gdata1, function (group) {
        var ret = group;
        var raw_date = _.where($scope.snapshots, {
          'id': group.csnapshotid
        });
        var d = raw_date[0].name;
        // var dd = utilService.dateToMonthAndYear(d);
        // ret.date = dd.month + " " + dd.year;
        ret.date = d;
        return ret;
      });
      $scope.gdata = gdata;
      $scope.avg = gdata[gdata.length - 1].cgroup1.toFixed(2);
      $scope.company_avg = gdata[gdata.length - 1].cgroup2;
      $scope.measureData.graph_data.avg = $scope.company_avg;

      var last = gdata[gdata.length - 1].cgroup2;
      var prev = gdata[gdata.length - 2] ? gdata[gdata.length - 2].cgroup2 : last;
      var upisgood = (graph_data.negative === 1);
      setUpperRightCornerIndications(last, prev, upisgood);
      var selectedData = gdata[gdata.length - 1];
      selectSnapshot(selectedData.date, selectedData.lsnapshotid, selectedData.csnapshotid, selectedData.lgroup1, selectedData.cgroup1);
      $scope.edata = createEmptyGraphData(gdata[gdata.length - 1].csnapshotid);
      $scope.empty_dates_range = [0, 10];
      changeDisplayedRange(0);

      var initExternalData = function () {
        _.each($scope.gdata, function (gd) {
          gd.lgroup3 = null;
          gd.cgroup3 = null;
          gd.ngroup3 = null;
          gd.score = null;
        });
      };
      var add3rdLineToGraph = function (external_data) {
        $scope.score_list = external_data.score_list;
        _.each($scope.gdata, function (gd, index) {
          var raw_data = _.where($scope.score_list, { 'snapshot_id': gd.csnapshotid});
          if (!_.isEmpty(raw_data)) {
            var last_snapshot_score = self.addScoreFromSnapshot($scope.gdata[index - 1], raw_data[0].score_normalize);
            var next_snapshot_score = self.addScoreFromSnapshot($scope.gdata[index + 1], raw_data[0].score_normalize);
            gd.lgroup3 = last_snapshot_score;
            gd.cgroup3 = raw_data[0].score_normalize;
            gd.score = raw_data[0].score;
            gd.ngroup3 = next_snapshot_score;
          }
        });
        $scope.pos = $element[0].children[0].children[0].getBoundingClientRect().width;
        utilService.setPositionToBubble($scope.pos, $scope.metricId);
      };

      $scope.$watch('externalDataMetric', function () {
        if ($scope.externalDataMetric) {
          initExternalData();
          add3rdLineToGraph($scope.externalDataMetric);
        }
      });
    };

    $scope.prev = function () {
      changeDisplayedRange(-1);
    };

    $scope.next = function () {
      changeDisplayedRange(1);
    };

    $scope.$watch('graphsize', function () {
      if ($scope.gdata) {
        changeDisplayedRange(0);
      }
    });

    $scope.setGraphResolution = function (val) {
      $scope.graph_resolution = val;
    };

    $scope.onDateSelect = function (date, lsid, csid, lgroupval, cgroupval) {
      selectSnapshot(date, lsid, csid, lgroupval, cgroupval);
    };

    $scope.dateSelected = function (myDate) {
      if (myDate === $scope.date_selected) {
        return {
          'background-color': "#edf1f7"
        };
      }
      return {};
    };

    var func = function (snapshots) {
      $scope.snapshots = snapshots;
      self.bind_measure_data_and_create_graph();
    };

    $scope.init = function () {
      $scope.data_for_gvis = {};
      $scope.name = {};
      $scope.avg = {};
      $scope.trend = {};
      $scope.displayed_range = [3, 6];
      $scope.graph_resolution = $scope.MONTH;
      $scope.graph_size = 3;
      $scope.date_selected = "none";
      $scope.$watch('measureData', function () {
        if ($scope.measureData && !_.isEmpty($scope.measureData)) {
          dataModelService.getSnapshots().then(func);
        }
      });
    };
  });
