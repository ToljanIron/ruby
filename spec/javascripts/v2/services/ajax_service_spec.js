/*globals describe, it, expect, beforeEach, angular, mock, module, inject, unused */
describe('ajaxService,', function () {
  'use strict';

  beforeEach(angular.mock.module('workships.services'));

  var service, httpBackend;

  beforeEach(inject(function (ajaxService, $httpBackend) {
    httpBackend = $httpBackend;
    service = ajaxService;
  }));

  describe('functionality', function () {
    it('should be defined', function () {
      expect(service).toBeDefined();
      expect(service.sendMsg).toBeDefined();
    });
  });

  describe('ajax calls,', function () {
    unused(httpBackend);
  });
});