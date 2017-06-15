/*globals angular, _*/
angular.module('workships.services').factory('initializeAppState', function (StateService) {
  'use strict';
  var initializeAppState = {};

  initializeAppState.initialize = function () {
    //Validation and defenition of tab - app state
    var tabValidator = function (x) {
      var acceptable_values = ['Dashboard', 'Workflow', 'Top Talent', 'Productivity', 'Collaboration', 'Explore', 'Settings'];
      return acceptable_values.indexOf(x) >= 0;
    };
    StateService.defineState({name: 'selected_tab', validator: tabValidator});

    //Validation and defenition of graph network filter data - app state
    var graphNetworkValidator = function (network_graph) {
      var ans = true;
      var acceptable_values = ["selected_network", 'selected_metric', 'selected_group_by', 'selected_group_ungroup_all', 'selected_edge'];
      _.forEach(_.keys(network_graph), function (n) {
        if (!_.includes(acceptable_values, n)) {
          ans = false;
          return ans;
        }
      });
      return ans;
    };
    StateService.defineState({name: 'network_graph', validator: graphNetworkValidator});

  };

  return initializeAppState;

});
