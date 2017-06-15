/*globals describe, it, expect, beforeEach, angular, mock, module, inject, unused */
describe('analyzeMediator,', function () {
  'use strict';

  beforeEach(angular.mock.module('workships.services'));

  var subject;

  beforeEach(inject(function (analyzeMediator) {
    subject = analyzeMediator;
  }));

  describe('functionality', function () {
    it('should be defined', function () {
      expect(subject).toBeDefined();
    });

    describe('init(), ', function () {
      var id;
      beforeEach(function () {
        id = 99;
        subject.init(id);
      });
      it('type should be defined', function () {
        expect(subject.type).toBeDefined();
      });
      it('id should be defined', function () {
        expect(subject.id).toBe(id);
      });
      it('selected_tab should be defined', function () {
        expect(subject.selected_tab).toBeDefined();
      });
    });

    describe('setSelected(id, type)', function () {
      var id, type;
      beforeEach(function () {
        id = 1;
        type = 'type';
        subject.setSelected(id, type);
      });
      it('should set id', function () {
        expect(subject.id).toBe(id);
      });
      it('should set type', function () {
        expect(subject.type).toBe(type);
      });

      describe('setGroupByIndex(index)', function () {
        var index;
        beforeEach(function () {
          index = 12;
          subject.setGroupByIndex(index);
        });
        it('should set group_by_index', function () {
          expect(subject.group_by_index).toBe(index);
        });
      });

      describe('getGroupByIndex()', function () {
        var index;
        beforeEach(function () {
          index = 12;
          subject.setGroupByIndex(index);
        });
        it('should return group_by_index', function () {
          expect(subject.getGroupByIndex()).toBe(index);
        });
      });

      describe('setMeasureByIndex(index)', function () {
        var index;
        beforeEach(function () {
          index = 12;
          subject.setMeasureByIndex(index);
        });
        it('should set measure_by_index', function () {
          expect(subject.measure_by_index).toBe(index);
        });
      });

      describe('getMeasureByIndex()', function () {
        var index;
        beforeEach(function () {
          index = 12;
          subject.setMeasureByIndex(index);
        });
        it('should return group_by_index', function () {
          expect(subject.getMeasureByIndex()).toBe(index);
        });
      });
    });
  });
});