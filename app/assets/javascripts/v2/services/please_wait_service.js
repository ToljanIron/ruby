/*globals angular */
angular.module('workships.services').factory('pleaseWaitService', function ($timeout, $interval, $http) {
  'use strict';

  var enabled = false;
  var checkForPendingRequests;

  return {
    enabled: function () { return enabled; },
    on: function () {
      $timeout(function () {
        enabled = true;

        if (!angular.isDefined(checkForPendingRequests)) {
          checkForPendingRequests = $interval(function () {
            // console.log('pending requests:', $http.pendingRequests.length);
            if ($http.pendingRequests.length === 0) {
              enabled = false;
              if (angular.isDefined(checkForPendingRequests)) {
                $interval.cancel(checkForPendingRequests);
                checkForPendingRequests = undefined;
              }
            }
          }, 300);
        }
      }, 300);
    }
  };
});
