/*globals describe, it, expect, beforeEach, angular, mock, module, inject, unused, _, setTimeout */
describe('editPresetMediatorService,', function () {
  'use strict';

  beforeEach(angular.mock.module('workships.services'));

  var service, dm, httpbackend, filterfactory;

  beforeEach(inject(function (editPresetMediator, dataModelService, $httpBackend, FilterFactoryService) {
    service = editPresetMediator;
    httpbackend = $httpBackend;
    dm = dataModelService;
    filterfactory = FilterFactoryService.create();
    dm.mock();
  }));

  it('should be defined', function () {
    expect(service).toBeDefined();
  });

  describe(',uploadPreset()', function () {
    var preset;
    beforeEach(function () {
      preset = dm.pins.active[0];
      service.uploadPreset(preset.id);
    });
    describe(',should upload the preset from generate and add to preset mediator obj ', function () {
      it(',should return details of the preset that choose, in generate mode', function () {
        expect(service.name).toEqual('pin1');
        expect(service.draft_or_new_preset).toBe(false);
        expect(service.definition.employees.length).toBe(1);
        expect(service.definition.conditions[0].vals[0]).toEqual('female');
        expect(service.getCretriaToPreset().length).toBe(1);
        expect(service.getEmployeesToPreset().length).toBe(1);
        expect(service.getGroupsToPreset().length).toBe(2);
        expect(service.isInNewOrDraftMode()).toBe(false);
      });
      it('sould check if curren preset selected', function () {
        expect(service.isCurrentPresetSelected(preset.id)).toEqual(true);
      });
    });
    describe(', selsectAll,  unselectAll() and another checked function', function () {
      it(',should un selected all the checkbox', function () {
        service.unselectAll();
        expect(service.definition.employees.length).toBe(0);
        expect(service.definition.groups.length).toBe(0);
        expect(service.isEmployeeChecked(service.getEmployeesToPreset()[0])).toBe(false);
      });
      it('should select all', function () {
        service.selectAll();
        expect(service.isEmployeeChecked(service.getEmployeesToPreset()[0])).toBe(true);
        expect(service.isGroupChecked(service.getGroupsToPreset()[1])).toBe(true);
        expect(service.isFilterChecked(service.getCretriaToPreset()[0])).toBe(true);
      });
    });
  });
  describe('open/close preset mode and check edit  preset mode ', function () {
    it('should open the preset panel', function () {
      service.openPresetPanel();
      expect(service.isInEditPresetMode()).toBe(true);
    });
    it('should close the preset panel', function () {
      service.closePresetPanel();
      expect(service.isInEditPresetMode()).toBe(false);
    });
    it('should change the preset mode', function () {
      service.changePresetMode();
      expect(service.isInEditPresetMode()).toBe(true);
    });
  });
  describe('can delete preset', function () {
    var preset, length;
    beforeEach(function () {
      preset = dm.pins.active[0];
      length = dm.pins.active.length;
      httpbackend.whenPOST('/API/delete_pins?id=1').respond(function () {
        return [200, {}, {}];
      });
      service.uploadPreset(preset.id);
    });
    it('should delete the preset from pins', function () {
      service.CanDelete(preset.id);
      httpbackend.flush();
      expect(dm.pins.active.length).toEqual(length - 1);
      expect(service.isInEditPresetMode()).toEqual(false);
      expect(service.id).toEqual(undefined);
      expect(service.show_alert_system).toEqual(false);
      expect(service.show_delete_alert_modal).toEqual(false);
    });
  });

  describe('change preset name', function () {
    var preset;
    beforeEach(function () {
      preset = dm.pins.active[0];
      httpbackend.whenPOST('/API/rename?id=1&name=ChangeName10').respond(function () {
        return [200, {}, {}];
      });
      service.uploadPreset(preset.id);
    });
    it('should change only the preset name without changes in the status', function () {
      service.name = 'ChangeName10';
      service.OnClickGeneratePin();
      httpbackend.flush();
      expect(dm.pins.active[0].name).toEqual('ChangeName10');
    });
  });

  describe('click to delete preset', function () {
    it('should show the delete preset modal', function () {
      service.onClickDelete();
      expect(service.show_delete_alert_modal).toEqual(true);
      expect(service.show_alert_system).toEqual(true);
    });
  });

  describe('save Draft scusess message', function () {
    it('should show a scusess message after create a preset and after 5 sec the message disappear', function () {
      service.saveDraftSucss();
      expect(service.show_delete_alert_modal).not.toEqual(true);
      expect(service.show_alert_system).toEqual(true);
      setTimeout(function () {
        expect(service.show_alert_system).toEqual(false);
      }, 10000);
    });
  });

  describe('create preset', function () {
    var emp_list;
    beforeEach(function () {
      emp_list = ['email1@mail.com', 'email2@mail.com'];
      filterfactory.mockFilterGroupIds([1, 3, 5]);
      var attrs = {
        age: ['15-24', '25-34', '35-44', '45-54', '55-64', '64+'],
        gender: ['male', 'female'],
      };
      filterfactory.mockFilter(attrs);
      service.create(filterfactory, emp_list);
    });
    it('Should create a new preset', function () {
      expect(service.id).toEqual(undefined);
      expect(service.getGroupsToPreset().length).toEqual(3);
      expect(service.getCretriaToPreset().length).toEqual(2);
      expect(service.isCheckboxExsists()).toEqual(true);
    });
    it('should add items to prest', function () {
      service.onClickAddEmployee('email3@mail.com');
      expect(service.definition.employees.length).toEqual(3);
      service.onClickFilterChecbox({ param: 'role', vals: [1, 4]});
      expect(service.definition.conditions.length).toEqual(3);
      service.onClickFilterGroupChecbox(4);
      expect(service.definition.groups.length).toEqual(4);
    });
  });
});
