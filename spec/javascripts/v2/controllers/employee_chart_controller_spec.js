/*globals _, describe, it , unused ,expect, beforeEach, angular, mock, module, $controller, document, window, mockController */
describe('employeeChartController,', function () {
  'use strict';

  var controller, module;

  beforeEach(function () {
    var mocked_controller = mockController('employeeChartController');
    controller = mocked_controller.controller;
    module = mocked_controller.module;

  });
  unused(module);

  it("should be a valid module", function () {
    expect(controller).toBeDefined();
  });

  describe('calculateDelta', function () {
    it('should get a org trend and emp trend, and return the delta between the org and employee ', function () {
      var args = [{ o_last_t: 5, o_current_t: 7, e_last_t: 7, e_current_t: 10},
                  { o_last_t: 5, o_current_t: 0, e_last_t: 5, e_current_t: 7},
                  { o_last_t: 2, o_current_t: 7, e_last_t: 6, e_current_t: 7},
                  { o_last_t: 2, o_current_t: 7, e_last_t: 4, e_current_t: 9}
                ];
      var expcted = [1, 7, -4, 0];
      var res;
      _.each(args, function (arg, i) {
        res = controller.calculateDelta(arg.o_last_t, arg.o_current_t, arg.e_last_t, arg.e_current_t);
        expect(res).toBe(expcted[i]);
      });
    });
  });

});