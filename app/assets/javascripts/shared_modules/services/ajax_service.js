/*globals angular*/

angular.module('workships.services').factory('ajaxService', ['$http',
  function ($http) {
    'use strict';

    var ajaxService = {};

    /* istanbul ignore next */
    function ajaxHandler(method, url, params, onSucc, onErr) {
      var header = {
        method: method,
        url: url,
        params: params,
      };
      $http(header)
        .success(function (data, status, headers, config) {
          onSucc(data, status, headers, config);
        })
        .error(function (data, status, headers, config) {
          //_TODO add to error log
          onErr(data, status, headers, config);
        });
    }

    /* istanbul ignore next */
    ajaxService.getPromise = function (method, url, params) {
      return $http({
        method: method,
        url: url,
        params: params,
      });
    };

    ajaxService.sendMsg = function (method, url, params, onSucc, onErr) {
      ajaxHandler(method, url, params, onSucc, onErr);
    };

    return ajaxService;
  }]);
