/*globals _, angular, beforeEach, expect, describe, it, inject */
describe('ceoReportService,', function () {
  'use strict';

  beforeEach(angular.mock.module('workships.services'));

  var service, httpBackend;

  beforeEach(inject(function (ceoReportService, $httpBackend) {
    service = ceoReportService;
    httpBackend = $httpBackend;
  }));

  it('should be defined', function () {
    expect(service.toggleShowReportModal).toBeDefined();
    expect(service.employeeChecked).toBeDefined();
    expect(service.addEmployeeToReport).toBeDefined();
    expect(service.removeEmployeeFromReport).toBeDefined();
    expect(service.sendFlaggedEmployeesToReport).toBeDefined();
  });

  describe('employeeChecked', function () {
    it('should return true if id is in array', function () {
      var res = service.employeeChecked([1], 1);
      expect(res).toEqual(true);
    });

    it('should return false if id is not in the array', function () {
      var res = service.employeeChecked([2], 1);
      expect(res).toEqual(false);
    });

    it('should return false if array is empty', function () {
      var res = service.employeeChecked([], 1);
      expect(res).toEqual(false);
    });
  });

  describe('addEmployeeToReport', function () {
    it('should add id to array if it\'s not there', function () {
      var array = [];
      service.addEmployeeToReport(array, 1);
      expect(array).toEqual([1]);
    });

    it('should not change the array if it already contains the id', function () {
      var array = [1];
      service.addEmployeeToReport(array, 1);
      expect(array).toEqual([1]);
    });
  });

  describe('removeEmployeeFromReport', function () {
    it('should remove id from array', function () {
      var array = [1];
      service.removeEmployeeFromReport(array, 1);
      expect(array).toEqual([]);
    });

    it('should do nothing if id is not in the array', function () {
      var array = [1];
      service.removeEmployeeFromReport(array, 2);
      expect(array).toEqual([1]);
    });

    it('should do nothing if the array is empty', function () {
      var array = [];
      service.removeEmployeeFromReport(array, 1);
      expect(array).toEqual([]);
    });
  });

  describe('sendFlaggedEmployeesToReport', function () {
    it('should not send http post when no employee_data', function () {
      var data = {'employee_data' : []};
      service.sendFlaggedEmployeesToReport(data);
      expect(function () {httpBackend.flush(); }).toThrow(new Error('No pending request to flush !'));
    });
  });
});