/*globals _, describe, it, unused ,expect, beforeEach, angular, mock, module, $controller, document, window, mockController */
xdescribe('signInController,', function () {
  'use strict';

  var scope;

  beforeEach(function () {
    var mocked_controller = mockController('signInController');
    scope = mocked_controller.scope;
  });

  describe('init()', function () {
    beforeEach(function () {
      scope.init();
    });
    it('user should be empty obj', function () {
      expect(scope.user).toEqual({});
    });
    it('error should be set', function () {
      expect(scope.error).toBeDefined();
    });
    it('change_user should be set', function () {
      expect(scope.change_user).toBeDefined();
    });
    it('error should be set', function () {
      expect(scope.change_password).toBeDefined();
    });
  });

  describe('someFunction()', function () {
    beforeEach(function () {
      var e = {
        preventDefault: unused
      };
      scope.init();
      scope.someFunction(e);
    });
    it('should change_user', function () {
      expect(scope.change_user).toBe(true);
    });
    it('should change_password', function () {
      expect(scope.change_password).toBe(true);
    });
  });

});