/*globals describe, it, expect, beforeEach, angular, mock, module, inject, unused */
describe('FilterFactoryService,', function () {
  'use strict';

  beforeEach(angular.mock.module('workships.services'));

  var service;
  var attr, value, filter;
  var example_filter = {
    attr_1: {
      a: true,
      A: false,
      AA: true,
    },
    attr_2: {
      b: false,
      B: true,
    },
    attr_3: {
      c: false,
      C: false,
    },
    friendship: {
      from: 1,
      to: 9
    }
  };

  beforeEach(inject(function (FilterFactoryService) {
    service = FilterFactoryService.create();
  }));

  it('should be defined', function () {
    expect(service).toBeDefined();
  });

  it('init()', function () {
    var attrs = {
      age: ['15-24', '25-34', '35-44', '45-54', '55-64', '64+'],
      gender: ['male', 'female'],
      friendship: ['from', 'to'],
    };
    var vals;
    service.init(attrs);
    filter = service.getFilter();
    vals = Object.keys(filter.age);
    expect(vals.length).toBe(6);
    vals = Object.keys(filter.gender);
    expect(vals.length).toBe(2);
    expect(vals.length).toBe(2);
    expect(filter.friendship.from).toBe(0);
    expect(filter.friendship.to).toBe(10);
  });

  describe('filter managment', function () {
    beforeEach(inject(function (FilterFactoryService) {
      service = FilterFactoryService.create();
      attr = 'some_attr';
      value = 'some_value';
      service.mockFilter(example_filter);
      filter = service.getFilter();
    }));
    describe('getFiltered()', function () {
      it('number of attributes should === (number of filter attributes that has at least one true value) + (all numeric attributes which with values other the from=0 to=10)', function () {
        var res = service.getFiltered();
        expect(Object.keys(res).length).toBe(3);
      });
      it('each attr should contain an array of matching true values', function () {
        var res = service.getFiltered();
        expect(res.attr_1).toEqual(['a', 'AA']);
        expect(res.attr_2).toEqual(['B']);
        expect(res.friendship[1]).toBe(9);
        expect(res.friendship[0]).toBe(1);
      });
    });

    describe('setting filter attributed and values', function () {
      describe('add()', function () {
        it('should create new attr if filter is empty, and set as true', function () {
          service.mockFilter({});
          filter = service.getFilter();
          service.add(attr, value);
          expect(filter[attr][value]).toBe(true);
        });
        it('should create new attr if not exist, and set as true', function () {
          service.add(attr, value);
          expect(filter[attr][value]).toBe(true);
        });
        it('should set attr as true if exist', function () {
          filter[attr] = {};
          filter[attr][value] = false;
          service.add(attr, value);
          expect(filter[attr][value]).toBe(true);
        });
      });
      describe('remove()', function () {
        it('should create new attr if not exist, and set as false', function () {
          service.remove(attr, value);
          expect(filter[attr][value]).toBe(false);
        });
        it('should set attr as true if exist', function () {
          filter[attr] = {};
          filter[attr][value] = true;
          service.remove(attr, value);
          expect(filter[attr][value]).toBe(false);
        });
      });
    });
  });
});
