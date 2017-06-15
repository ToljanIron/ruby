/*globals angular , $ ,  window , KeyLines , _ , unused */
angular.module('workships').controller('editPinController', function ($scope, ajaxService, dashboradMediator, analyzeMediator, directoryMediator, editPresetMediator, overlayBlockerService, ceoReportService) {
  'use strict';
  var self = this;

  self.updatePinNameOnServer = function (pin) {
    var method = 'POST';
    var url = '/API/rename';
    var params = {
      name: pin.name,
      id: pin.id
    };
    var succ = function (data) {
      unused(data);
    };
    var err = function () {
      unused();
    };
    ajaxService.sendMsg(method, url, params, succ, err);
  };

  self.deletePinOnServer = function (pin) {
    var method = 'POST';
    var url = '/API/delete_pins';
    var params = {
      id: pin.id
    };
    var succ = function (data) {
      unused(data);
    };
    var err = function () {
      unused();
    };
    ajaxService.sendMsg(method, url, params, succ, err);
  };

  self.ChangeToDefaultState = function () {
    $scope.selected.init();
  };

  $scope.showRenamePin = function () {
    if ($scope.page.id === 3) {
      ceoReportService.toggleShowReportModal('preset-menu');
      $scope.edit_preset.openPresetPanel();
      $scope.edit_preset.uploadPreset($scope.pin.id);
    }
  };

  $scope.modalOn = function () {
    return overlayBlockerService.isElemDisplayed('preset-menu');
  };

  $scope.deletePin = function (pin) {
    $scope.delete_mode = true;
    var index = $scope.pinList.indexOf(pin);
    if ($scope.selected.id === pin.id) {
      self.ChangeToDefaultState();
    }
    self.deletePinOnServer(pin);
    $scope.pinList.splice(index, 1);
  };
  $scope.selectPin = function (pin) {
    $scope.selected.setSelected(pin.id, "pin");
  };

  $scope.renamePin = function () {
    setTimeout(function () {
      if ($scope.pin && $scope.delete_mode !== true) {
        self.updatePinNameOnServer($scope.pin);
        $scope.showRename = true;
      }
      $scope.focusTriger = false;
      $scope.pin_in_edit_mode = 0;
      $scope.delete_mode = false;
    }, 200);
  };
  $scope.init = function () {
    $scope.hover = false;
    $scope.showRename = true;
    $scope.edit_preset = editPresetMediator;
    $scope.edit_pressed = false;
    if ($scope.page.id === 1) {
      $scope.selected = dashboradMediator;
    } else if ($scope.page.id === 2) {
      $scope.selected = analyzeMediator;
      $scope.filter_group_ids = $scope.selected.filter.getFilterGroupIds();
    } else {
      $scope.selected = directoryMediator;
    }
  };
  $scope.isDirectoryPage = function(){
    return $scope.page.id == 3;
  }

});
