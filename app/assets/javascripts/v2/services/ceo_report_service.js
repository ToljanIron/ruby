/*globals _, document, angular*/
angular.module('workships.services').factory('ceoReportService', function ($http, overlayBlockerService) {
  'use strict';

  var ceoReportService = {};

  ceoReportService.toggleShowReportModal = function (element_name) {
    if (!overlayBlockerService.isElemDisplayed(element_name)) {
      overlayBlockerService.block(element_name);
    } else {
      overlayBlockerService.unblock();
    }
  };

  ceoReportService.toggleShowReportModalIfNotMetrics = function (element_name, show_report_modal) {
    if (!show_report_modal) {
      return;
    }
    if (!overlayBlockerService.isElemDisplayed(element_name)) {
      overlayBlockerService.block(element_name);
    } else {
      overlayBlockerService.unblock();
    }
  };

  ceoReportService.employeeChecked = function (emp_array, id) {
    return _.contains(emp_array, id);
  };

  ceoReportService.addEmployeeToReport = function (emp_array, id) {
    if (!_.contains(emp_array, id)) {
      emp_array.push(id);
    }
  };

  ceoReportService.removeEmployeeFromReport = function (emp_array, id) {
    _.remove(emp_array, function (id_to_report) {
      return id_to_report === id;
    });
  };

  ceoReportService.sendFlaggedEmployeesToReport = function (data) {
    if (data.employee_data.length > 0) {
      $http.post('/API/init_report_xls', data).success(function () {
        var link = '/API/create_and_download_report_xls?' + 'group_id=' + data.group_id + '&pin_id=' + data.pin_id;
        var download_link = document.createElement('a');
        download_link.href = link;
        download_link.click();
        download_link.remove();
      });
    }
  };

  return ceoReportService;
});
