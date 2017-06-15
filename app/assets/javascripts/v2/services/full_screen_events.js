/*globals _,fullScreenEventService, document,window, angular*/
angular.module('workships.services').factory('fullScreenEventService', function () {
  'use strict';

  var fullScreenEventService = {};
  fullScreenEventService.event_status = {'event': false };

  fullScreenEventService.setEvent = function (event_happen) {
    fullScreenEventService.event_status.event =  event_happen;
  };

  fullScreenEventService.getFullScreenEventStatus = function () {
    return fullScreenEventService.event_status.event;
  };

  return fullScreenEventService;

});
