/*globals angular, alert*/

angular.module('workships-mobile.services').factory('ajaxService', ['$http', 'mobileAppService',
  function ($http, mobileAppService) {
    'use strict';

    var ajaxService = {};

    function getPromise(method, url, params, data) {
      return $http({
        method: method,
        url: url,
        params: params,
        data: data
      });
    }

    function loadEmployeesFromServer(_params) {
      var method = 'GET';
      var url = '/get_questionnaire_employees';
      var params = {token: _params.token, is_snowball : _params.is_snowball};
      return getPromise(method, url, params);
    }

    function loadQuestionFromServer(_params) {
      var method = 'POST';
      var url = '/get_next_question';
      var params = { data: _params };
      return getPromise(method, url, null, params);
    }

    function closeQuestion(_params) {
      var method = 'POST';
      var url = '/close_question';
      var params = { data: _params };
      return getPromise(method, url, null, params);
    }

    function updateReplies(_params) {
      var method = 'POST';
      var url = '/update_replies';
      var params = { data: _params };
      return getPromise(method, url, null, params);
    }

    function loadOverlayEntityConfiguration() {
      var method = 'GET';
      var url = '/get_overlay_entity_configuration';
      var params = {};
      return getPromise(method, url, params);
    }

    function changeStatus(_params) {
      var method = 'POST';
      var url = '/change_entity_configuration_status';
      var params = _params;
      return getPromise(method, url, params);
    }

    function keepAlive(counter) {
      var method = 'GET';
      var url = '/keep_alive';
      var params = {counter : counter};
      return getPromise(method, url, params);
    }

    function getAutoCompleteData(_params){
      var method = 'POST';
      var url = '/questionnaiare/participant_automcomplete';
      var params = _params;
      return getPromise(method, url, params);
    }

    ajaxService.getAutoCompleteData = function (params) {
      return getAutoCompleteData(params);
    }

    function createUnverifiedEmployee(_params) {
      var method = 'POST';
      var url = '/add_unverfied_participant';
      var params = _params;
      return getPromise(method, url, params);
    }

    ajaxService.createUnverifiedEmployee = function (params) {
      return createUnverifiedEmployee(params);
    }

    function getGroups(_params) {
      var method = 'GET';
      var url = '/get_questionnaire_groups';
      var params = _params;
      return getPromise(method, url, params);
    }

    ajaxService.getGroups = function (params) {
      return getGroups(params);
    }

    ajaxService.getOverlayEntityConfiguration = function () {
      return loadOverlayEntityConfiguration();
    };

    ajaxService.get_employees = function (params) {
      return loadEmployeesFromServer(params);
    };

    ajaxService.get_next_question = function (params) {
      return loadQuestionFromServer(params);
    };

    ajaxService.close_question = function(params) {
      return closeQuestion(params);
    };

    ajaxService.update_replies = function(params) {
      return updateReplies(params);
    };

    ajaxService.changeEntityConfigurationStatus = function (params) {
      return changeStatus(params);
    };

    ajaxService.keepAlive = function (server) {
      var pending_request = false;
      var onSucc = function () {
        pending_request = false;
        server.alive = true;
        mobileAppService.hideConnectionLostOverlayBlocker();
      };
      var onErr = function () {
        pending_request = false;
        server.alive = false;
        mobileAppService.displayConnectionLostOverlayBlocker({unblock_on_click: false});
      };
      var counter = 0;
      setInterval(function () {
        if (!pending_request) {
          counter++;
          pending_request = true;
          keepAlive(counter).then(onSucc, onErr);

        }
      }, 300000);
    };

    return ajaxService;
  }]);
