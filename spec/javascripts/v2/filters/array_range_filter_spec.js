/*globals describe, it, expect, beforeEach, angular, mock, module, inject, unused */
describe('arrayRangeFilter', function () {
  'use strict';
  var filter;

  beforeEach(function () {
    module('workships.filters');
    inject(function ($filter) {
      filter = $filter('arrayRangeFilter');
    });
  });

  describe('when data is valid', function () {
    it('should return sub array within range', function () {
      var data = [10, 11, 12, 13, 14, 15, 16, 17, 18];
      var range = [1, 4];
      var res = filter(data, range);
      expect(res).toEqual([11, 12, 13, 14]);
    });
  });

  describe('when data is invalid', function () {
    it('should return empty array', function () {
      var data = null;
      var range = [1, 4];
      var res = filter(data, range);
      expect(res).toEqual([]);
    });
  });
});