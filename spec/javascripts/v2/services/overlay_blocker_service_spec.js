/*globals _, describe, it, expect, beforeEach, angular, mock, module, inject, unused */
describe('overlayBlockerService,', function () {
  'use strict';

  beforeEach(angular.mock.module('workships.services'));

  var subject;
  function generate_example_elements(val) {
    return [
      {name: 'e1', displayed: val},
      {name: 'e2', displayed: val},
    ];
  }


  beforeEach(inject(function (overlayBlockerService) {
    subject = overlayBlockerService;
  }));

  it('should be defined', function () {
    expect(subject).toBeDefined();
  });

  describe('block()', function () {
    describe('when no element name is given', function () {
      beforeEach(function () {
        subject.block();
      });
      it('should set as blocked', function () {
        expect(subject.isBlocked()).toBe(true);
      });
      it('should set as blocked', function () {
        expect(subject.isBlocked()).toBe(true);
      });
    });

    describe('when element name is given', function () {
      var element_name = 'e1';
      var example_elements;
      beforeEach(function () {
        example_elements = generate_example_elements(false);
        subject.mock_with(example_elements);
        subject.block(element_name);
      });
      it('should set as blocked', function () {
        expect(subject.isBlocked()).toBe(true);
      });
      it('should set as blocked', function () {
        expect(subject.isBlocked()).toBe(true);
      });
      it('should toggle e1 displayed value', function () {
        var e1 = example_elements[0];
        expect(e1.displayed).toBe(true);
      });
      it('should not change e2 displayed value', function () {
        var e2 = example_elements[1];
        expect(e2.displayed).toBe(false);
      });
    });
  });

  describe('unblock()', function () {
    var example_elements;
    beforeEach(function () {
      example_elements = generate_example_elements(true);
      subject.mock_with(example_elements);
      subject.unblock();
    });
    it('should set as unblocked', function () {
      expect(subject.isBlocked()).toBe(false);
    });
    it('should set as unblocked', function () {
      _.each(example_elements, function (elem) {
        expect(elem.displayed).toBe(false);
      });
    });
  });

  describe('isElemDisplayed()', function () {
    var example_elements;
    beforeEach(function () {
      example_elements = generate_example_elements(true);
      example_elements[1].displayed = false;
      subject.mock_with(example_elements);
    });
    it('e1 should be displayed', function () {
      expect(subject.isElemDisplayed('e1')).toBe(true);
    });
    it('e2 should not be displayed', function () {
      expect(subject.isElemDisplayed('e2')).toBe(false);
    });
  });
});