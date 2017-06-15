/*globals angular, _ */
angular.module('workships.directives').directive('employeeStatus', function () {
  'use strict';
  return {
    scope: {
      status: '=employeeStatus'
    },
    template: "<div>" +
                "<div class='bullet' style='background-color:{{current_status.color}}'></div>" +
                "<div class='status'>{{current_status.display}}</div>" +
              "</div>",
    link: function (scope) {
      var statuses = [{
        status: 'notstarted',
        display: 'Not Started',
        color: '#fc0001'
      }, {
        status: 'in_process',
        display: 'In Progress',
        color: '#fed932'
      }, {
        status: 'entered',
        display: 'In Progress',
        color: '#fed932'
      }, {
        status: 'completed',
        display: 'Completed',
        color: '#5cb960'
      }];

      scope.current_status = _.find(statuses, function (obj) {
        return obj.status === scope.status;
      });
    }
  };
});