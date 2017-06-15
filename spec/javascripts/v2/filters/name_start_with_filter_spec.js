/*globals describe, it, expect, beforeEach, angular, mock, module, inject, unused, _ */
describe('nameStartWith', function () {
  'use strict';
  var filter;

  beforeEach(function () {
    module('workships.filters');
    inject(function ($filter) {
      filter = $filter('nameStartWith');
    });
  });

  describe('when data is valid', function () {
    var valid_names = ['aaa', 'Aaa', 'xx Aa', 'xx aa', 'xx yy aa',  'bb', 'cc'];
    it('should return sub array with memebers that start with prefix', function () {
      var valid_data = _.map(valid_names, function (name) {
        return {name: name};
      });
      var prefix = 'aa';
      var res = filter(valid_data, prefix);
      var expected =  [{name: 'aaa'}, {name: 'Aaa'}, {name: 'xx Aa'}, {name: 'xx aa'}, {name: 'xx yy aa'}];
      expect(res).toEqual(expected);
    });
  });
});