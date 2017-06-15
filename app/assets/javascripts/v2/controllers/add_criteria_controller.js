/*globals angular */

angular.module('workships').controller('AddCriteriaCtrl', function ($scope, analyzeMediator, overlayBlockerService) {
  'use strict';

  $scope.getFilterTitle = function (filter) {
    return filter.title.replace('_', ' ');
  };

  $scope.filterChecked = function (filter) {
    return _.contains($scope.show_criteria, filter.title);
  };

  $scope.checkFilter = function (filter) {
    $scope.show_criteria = _.union($scope.show_criteria, [filter.title]);
  };

  $scope.uncheckFilter = function (filter) {
    $scope.show_criteria.splice($scope.show_criteria.indexOf(filter.title), 1);
  };

  $scope.clearAll = function () {
    $scope.show_criteria.splice(0, $scope.show_criteria.length);
  };

  $scope.anyChecked = function () {
    return $scope.show_criteria !== undefined && $scope.show_criteria.length > 0;
  };

  $scope.howManyChecked = function () {
    return $scope.show_criteria.length;
  };

  $scope.addSelected = function () {
    if (_.isEmpty($scope.show_criteria)) { return; }
    $scope.selected.show_criteria.splice(0, $scope.selected.show_criteria.length);
    $scope.selected.show_criteria = _.union($scope.selected.show_criteria, $scope.show_criteria);
    overlayBlockerService.unblock();
  };

  $scope.init = function () {
    $scope.selected = analyzeMediator;
    $scope.show_criteria = _.clone($scope.selected.show_criteria);
  };
});