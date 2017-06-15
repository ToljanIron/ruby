/*globals _, describe, it, expect, beforeEach, angular, mock, module, inject, unused */
describe('utilService,', function () {
  'use strict';

  beforeEach(angular.mock.module('workships.services'));

  var service;

  beforeEach(inject(function (utilService) {
    service = utilService;
  }));

  describe('functionality', function () {
    it('should be defined', function () {
      expect(service).toBeDefined();
    });
  });

  describe('dateToMonthAndYear(),', function () {
    describe('with valid data', function () {

      it('should return the month and year from Date', function () {
        var d = new Date("October 13, 2014 11:13:00");
        var res = service.dateToMonthAndYear(d);
        expect(res.month).toBe('Oct');
        expect(res.year).toBe('2014');
      });

      it('should return the month and year from Date', function () {
        var d = new Date("Tue Dec 01 2015 00:00:00 GMT+0200");
        var res = service.dateToMonthAndYear(d);
        expect(res.month).toBe('Dec');
        expect(res.year).toBe('2015');
      });

      it('should return the month and year from Date', function () {
        var d = new Date(86400000);
        var res = service.dateToMonthAndYear(d);
        expect(res.month).toBe('Jan');
        expect(res.year).toBe('1970');
      });

    });
  });

  describe('changeObjectKeys()', function () {
    var arr, arr2, obj;
    beforeEach(function () {
      arr = ['k1', 'k2'];
      arr2 = ['k11', 'k22'];
      obj = {
        k1: 0,
        k2: 1
      };
    });
    it('should replace obj keys for arr1 to arr2', function () {
      service.changeObjectKeys(obj, arr, arr2);
      expect(obj.k1).toBeUndefined();
      expect(obj.k2).toBeUndefined();
      expect(obj.k11).toBe(0);
      expect(obj.k22).toBe(1);
    });
  });

  describe('capitaliseAndTrimFirstWord(str)', function () {
    it('should return first word of str with first letter capitalized', function () {
      var i, res;
      var str_examples = ['single', 'string_with_some_words'];
      var expected_res = ['Single', 'String'];
      for (i = 0; i < str_examples.length; i++) {
        res = service.capitaliseAndTrimFirstWord(str_examples[i]);
        expect(res).toEqual(expected_res[i]);
      }
    });
  });

  describe('splitAndCapitalise(str)', function () {
    it('should return words of str with first letter capitalized', function () {
      var i, res;
      var str_examples = ['single', 'string_with_some_words'];
      var expected_res = ['Single', 'String With Some Words'];
      for (i = 0; i < str_examples.length; i++) {
        res = service.splitAndCapitalise(str_examples[i]);
        expect(res).toEqual(expected_res[i]);
      }
    });
  });

  describe('spiltBeforeDash(str)', function () {
    it('should first word before "-"', function () {
      var i, res;
      var str_examples = ['single', 'string-dash', 'long-string-with-some-words'];
      var expected_res = ['single', 'string', 'long'];
      for (i = 0; i < str_examples.length; i++) {
        res = service.spiltBeforeDash(str_examples[i]);
        expect(res).toEqual(expected_res[i]);
      }
    });
  });

  describe('displayFormattedTitle(str)', function () {
    it('should replace "_" with " " and capitalize every word', function () {
      var i, res;
      var str_examples = ['single', 'string_dash', 'long_string_with_some_words'];
      var expected_res = ['Single', 'String Dash', 'Long String With Some Words'];
      for (i = 0; i < str_examples.length; i++) {
        res = service.displayFormattedTitle(str_examples[i]);
        expect(res).toEqual(expected_res[i]);
      }
    });
  });

  describe('getObjKeys(obj)', function () {
    it('when obj is valid should return keys of obj', function () {
      var obj = {a: 1, b: 2};
      var res = service.getObjKeys(obj);
      expect(res).toEqual(['a', 'b']);
    });
    it('when obj is invalid should return null', function () {
      var obj = null;
      var res = service.getObjKeys(obj);
      expect(res).toBe(null);
    });
  });

});
