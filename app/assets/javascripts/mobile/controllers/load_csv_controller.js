/*globals angular, unused */
angular.module('workships-mobile').controller('loadCsvController', function ($scope, ajaxService) {
  'use strict';

  $scope.init = function () {
    ajaxService.getOverlayEntityConfiguration().then(function (response) {
      $scope.overlay_entity_configuration = response.data.overlay_entity_configuration;
    });
  };

  $scope.onChangeEntityConf = function (overlay_entity) {
    var activity = !overlay_entity.active;
    ajaxService.changeEntityConfigurationStatus({ overlay_entity_id: overlay_entity.id, activity: activity}).then(function (response) {
      overlay_entity.active = response.data.activity;
    });
  };


});