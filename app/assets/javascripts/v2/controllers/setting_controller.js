/*globals angular , window, unused, _  */
angular.module('workships').controller('settingController', function ($scope, dataModelService) {
  'use strict';
  var setSnapshotList = function (snapshot_list) {
    $scope.snapshot_list = snapshot_list;
  };

  var setExternalDataList = function (external_data) {
    $scope.external_data_list = external_data;
  };

  $scope.addExternalMetric = function () {
    var temp = { metric_name: '', score_list: [] };
    $scope.external_data_list.push(temp);
  };
  $scope.addSnapshotScore = function (metric_data) {
    if (metric_data.length >= $scope.snapshot_list.length) {
      return;
    }
    var temp = { snapshot_id: $scope.snapshot_list[metric_data.length].sid, score: 0};
    metric_data.push(temp);
  };
  $scope.removeScore = function (snapshot_list, i) {
    snapshot_list.splice(i, 1);
  };
  $scope.removeExternalMetric = function (metric, index) {
    var id = metric.id;
    if (id) {
      $scope.remove_list.push(id);
    }
    $scope.external_data_list.splice(index, 1);
  };

  var validateData = function () {
    $scope.submit_error = false;
    $scope.submit_error_messeage = null;
    _.each($scope.external_data_list, function (metric) {
      if (_.isEmpty(metric.metric_name)) {
        $scope.submit_error_messeage = 'Metric name Cant be blank';
        $scope.submit_error = true;
      }
      var snapshot_id_list = [];
      _.each(metric.score_list, function (score) {
        if (!_.isNumber(score.score)) {
          $scope.submit_error_messeage = 'score is not a number!!';
          $scope.submit_error = true;
        }
        if (_.include(snapshot_id_list, score.snapshot_id)) {
          $scope.submit_error_messeage = 'Dupliacte Snapshot in the Metric:  ' + metric.metric_name;
          $scope.submit_error = true;
        }
        snapshot_id_list.push(score.snapshot_id);
      });
    });
  };

  $scope.$watch('external_data_list', function () {
    $scope.submit_error = false;
    $scope.submit_error_messeage = null;
  }, true);

  $scope.submit = function () {
    validateData();
    if (!$scope.submit_error) {
      var data = {remove_list : $scope.remove_list,  external_data_list: $scope.external_data_list};
      dataModelService.editExternalDataMetric({data : data}, true);
      $scope.external_data_list = [];
      $scope.remove_list = [];
      dataModelService.getExternalDataList(true).then(setExternalDataList);
    }
  };
  //  ******** Watch **********

  $scope.init = function () {
    $scope.remove_list = [];
    dataModelService.getSnapshotList().then(setSnapshotList);
    dataModelService.getExternalDataList(true).then(setExternalDataList);
  };
});
