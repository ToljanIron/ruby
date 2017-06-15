require 'spec_helper'
#require './spec/factories/company_factory.rb'
include SessionsHelper

describe PinsController, type: :controller do
  before do
    # login with hr
    log_in_with_dummy_user_with_role(1)

    (1..5).each do |i|
      definition = '{"conditions": [{"param": "rank_id", "vals": [2]}, {"param": "title", "vals": [3, 1]}], "employees": ["a@email.com"]}'
      ui_definition = '{"conditions": [{"param": "rank_id", "vals": [2]}, {"param": "title", "vals": [3, 1]}], "employees": [], "groups": []}'
      name = "pin#{i}"
      Pin.create(company_id: 1, name: name, definition: definition, ui_definition: ui_definition)
    end

    EmployeesPin.create(pin_id: 1, employee_id: 1)
    EmployeesPin.create(pin_id: 1, employee_id: 2)
  end

  after do
    DatabaseCleaner.clean_with(:truncation)
  end

  it ', should be signed in' do
    expect(current_user).to eq(@user)
  end

  describe ', check actions' do
    it 'should return array of size 5' do
      res = get :show, company_id: 1
      res = JSON.parse res.body
      expect(res['drafts'].length).to eq(5)
    end

    it 'should rename correctly' do
      NAME = 'newname'
      get :rename, name: NAME, id: 1
      p = Pin.find(1)
      expect(p.name).to eq(NAME)
    end

    it 'should delete  pin and entries from empoyees_pins' do
      post :delete, id: 1
      expect(Pin.find(1).active).to eq(false)
      expect(EmployeesPin.where(pin_id: 1).length).to eq(0)
    end

    it 'should return exception if id is not exsist and not change the Pins' do
      res = post :delete, id: 15
      res =  JSON.parse res.body
      expect(res['message']).to eq('Fail')
    end

    it 'should return [] if there are not employess in pin_id' do
      res = get :show_preset_employess, pid: 10
      res = JSON.parse res.body
      expect(res).to eq([])
    end
    it 'should return [1,2] if there pin_id eq to 1' do
      res = get :show_preset_employess, pid: 1
      res = JSON.parse res.body
      expect(res).to eq([1, 2])
    end
  end

  describe 'Should create a new pin in not exsist' do
    it 'Should create a new pin if not exsist' do
      count = Pin.count
      params = { name: 'testpin', action_button: 1 }
      params[:definition] =  '{"conditions": [], "employees": ["a@email.com"], "groups": [20]}'
      post :new, params
      expect(Pin.count).to be > count
      expect(Pin.last.status).to eq('draft')
      expect(Pin.last.status).to_not eq('pre_create_pin')
    end
    it 'Should update the pin to unactive and create a new pin' do
      count = Pin.count
      params = { id: 1, name: 'testpin', action_button: 2 }
      params[:definition] = '{"conditions": [], "employees": [], "groups": []}'
      post :new, params
      expect(Pin.count).to be > count
      expect(Pin.find_by(id: 1).active).to eq(false)
      expect(Pin.last.status).to eq('pre_create_pin')
    end
    it 'Should update not change the pin status and update the pin' do
      count = Pin.count
      params = { id: 1,  name: 'change_pin', action_button: 1 }
      params[:definition] = '{"conditions": [], "employees": [], "groups": []}'
      post :new, params
      expect(Pin.count).to eq(count)
      expect(Pin.find(1).status).to eq('draft')
      expect(Pin.find(1).name).to eq('change_pin')
    end
  end

  describe 'Test permissions' do
    before do
      DatabaseCleaner.clean_with(:truncation)
    end

    it 'Should be able to create a pin if the user is admin' do
      # login with admin
      log_in_with_dummy_user_with_role(0)
      post :new, company_id: 1, name: 'testpin', id: 1, definition: '{"conditions": [], "employees": [], "groups": []}'
      expect(response.status).to eq(200)
      expect(response.message).to eq('OK')
    end

    it 'Should be able to create a pin if the user is hr manager' do
      # login with hr
      log_in_with_dummy_user_with_role(1)
      post :new, company_id: 1, name: 'testpin', id: 1, definition: '{"conditions": [], "employees": [], "groups": []}'
      expect(response.status).to eq(200)
      expect(response.message).to eq('OK')
    end
  end
end
