/*globals angular, _ */
angular.module('workships').controller('ChooseLayerFilterCtrl', function ($scope, analyzeMediator, overlayBlockerService, graphService, dataModelService, pleaseWaitService) {
  'use strict';

  $scope.filterChecked = function (name) {
    return _.contains($scope.show_filters, name.split(' (')[0]);
  };

  $scope.keywordChecked = function (word) {
    return _.contains(_.keys($scope.keywords_names), word);
  };

  $scope.checkFilter = function (name) {
    $scope.show_filters = _.union($scope.show_filters, [name.split(' (')[0]]);
  };

  function addToKeywordNamesFilter(name) {
    $scope.keywords_names[name] = true;
  }

  $scope.onChooseInSearch = function(name) {
    if (name.indexOf(' (') === -1) {
      addToKeywordNamesFilter(name);
    } else {
      $scope.checkFilter(name);
    }
    $scope.clearSearch();
  };

  $scope.uncheckFilter = function (name) {
    if ($scope.show_filters.indexOf(name.split(' (')[0]) === -1) {
      delete $scope.keywords_names[name];
    } else {
      $scope.show_filters.splice($scope.show_filters.indexOf(name.split(' (')[0]), 1);
    }
  };

  $scope.uncheckPillBox = function(name) {
    $scope.show_filters.splice($scope.show_filters.indexOf(name), 1);
  };

  $scope.clearAll = function () {
    $scope.show_filters = _.reject($scope.show_filters, function (f) {
      return _.includes(_.map(_.keys($scope.selected.layer.values), function (v) {
        return v.split(' (')[0];
      }), f);
    });
    // $scope.show_filters.splice(0, $scope.show_filters.length);
    if ($scope.keywords_names) { $scope.keywords_names = {}; }
  };

  $scope.howManyChecked = function () {
    return _.inject($scope.show_filters, function (init, f) {
      if (_.includes(_.map(_.keys($scope.selected.layer.values), function (v) {
        return v.split(' (')[0];
      }), f)) {
        return init + 1;
      } return init;
    }, 0) + _.keys($scope.keywords_names).length;
  };

  function includeLayers() {
    if (analyzeMediator.overlay_entity_group_id === undefined) {
      analyzeMediator.toogle_on_overlay = !analyzeMediator.toogle_on_overlay;
      return;
    }
    //var entitiy_group_ids_of_showing = dataModelService.fetchGroupIdsFromOverlayEntity(analyzeMediator.shown_overlay_groups);
    //dataModelService.getOverlaySnapshotData(entitiy_group_ids_of_showing, analyzeMediator.entity_ids_of_showing || [], graphService.group_id, graphService.sid, true).then(function () {
    //  analyzeMediator.toogle_on_overlay = !analyzeMediator.toogle_on_overlay;
    //});
  }

  $scope.addSelected = function () {
    // if (_.isEmpty($scope.show_filters) && _.isEmpty(_.keys($scope.keywords_names))) { return; }
    $scope.selected.shown_overlay_groups.splice(0, $scope.selected.shown_overlay_groups.length);
    $scope.selected.shown_overlay_groups = _.union($scope.selected.shown_overlay_groups, $scope.show_filters);
    //var entitiy_group_ids_of_showing = dataModelService.fetchGroupIdsFromOverlayEntity($scope.selected.shown_overlay_groups);
    _.each(_.keys($scope.selected.layer.values), function (k) {
      $scope.selected.layer.values[k] = _.include($scope.show_filters, k.split(' (')[0]);
    });
    if ($scope.selected.layer.title === 'keywords') {
      $scope.selected.filter.getFilter().keywords_names = $scope.keywords_names;
      $scope.selected.entity_ids_of_showing = _(dataModelService.keywords).filter(function (keyword) {
        return _.any(_.keys($scope.keywords_names), function (name) {
          return keyword.name === name;
        });
      }).pluck('id').values();
    }
    overlayBlockerService.unblock();
    pleaseWaitService.on();
    //dataModelService.getOverlaySnapshotData(entitiy_group_ids_of_showing || [], $scope.selected.entity_ids_of_showing || [], graphService.group_id, graphService.sid, true).then(function () {
    //  $scope.selected.layer.on = true;
    //  $scope.selected.toggleAllLayers();
    //  includeLayers();
    //  graphService.preSetOverlayData();
    //});
  };

  $scope.filterFilters = function () {
    if ($scope.search === undefined || $scope.search === '') {
      $scope.filtered_values = _.keys($scope.selected.layer.values);
    }
    $scope.filtered_values = _.filter(_.keys($scope.selected.layer.values), function (k) {
      return k.split(' (')[0].indexOf($scope.search) > -1;
    });
  };

  function getFilerList() {
    return function () {
      var res = [];
      _.each($scope.selected.layer.values, function (val, key) {
        angular.noop(val);
        if ($scope.filterChecked(key)) { return; }
        res.push({
          name: key,
          display_name: key.split(' (')[0]
        });
      });
      if ($scope.selected.layer.title === 'keywords') {
        _.each($scope.keywords, function (keyword) {
          res.push({
            name: keyword.name,
            display_name: keyword.name
          });
        });
      }
      return res;
    };
  }

  var isHebrew = function(text) {
    if (text === undefined) { return false; }
    return (text.match(/[\u05D0-\u05FF]+/) !== null);
  };

  $scope.setTextDirection = function(name, num) {
    if ( isHebrew(name) ) {
      return '(' + num + ') ' + name;
    }
    return name + ' (' + num + ')';
  };

  $scope.augmentText = function(text, shouldAugment) {
    if (shouldAugment === false) { return text; }
    return text.substring(0, text.lastIndexOf(')')) + ' keywords)';
  };

  $scope.clearSearch = function () {
    $scope.search = '';
    $scope.filtered_values = _.keys($scope.selected.layer.values);
  };

  $scope.pillsToShow = function () {
    return _.union(_.filter($scope.show_filters, function (f) {
      return _.any(_.keys($scope.selected.layer.values), function (v) {
        return v.split(' (')[0] === f;
      });
    }), _.filter(_.keys($scope.keywords_names), function (f) {
      return _.any(_.keys($scope.keywords_names), function (v) {
        return v === f;
      });
    }));
  };

  $scope.setStyleHeight = function() {
    var height = ($scope.selected.layer.title === 'keywords' ? '435px' : '417px');
    return {'height':height};
  };

  $scope.init = function () {
    $scope.selected = analyzeMediator;
    $scope.lodash = _;
    $scope.show_filters = _.clone($scope.selected.shown_overlay_groups);
    $scope.search_list = getFilerList();
    $scope.filtered_values = _.keys($scope.selected.layer.values);
    $scope.keywords_names = {};
    if ($scope.selected.layer.title === 'keywords') {
      $scope.keywords_names = _.cloneDeep($scope.selected.filter.getFilter().keywords_names);
      dataModelService.getKeywords().then(function (data) {
        $scope.keywords = data;
      });
    }
  };
});
