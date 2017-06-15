include SessionsHelper
SAVED_AS_DRAFT = 1
GENERATE = 2
class PinsController < ApplicationController
  def new
    authorize :pin, :update?
    company_id = current_user.company_id
    action_button = params[:action_button].to_i
    name = params[:name]
    id = params[:id].to_i
    all_definition = JSON.parse params[:definition]
    ui_definition = all_definition.to_json
    definition_to_preset = {}
    definition_to_preset[:conditions] = create_condition_list(all_definition['conditions'])
    definition_to_preset[:groups] = all_definition['groups']
    definition_to_preset[:employees] = all_definition['employees']
    definition_to_preset = definition_to_preset.to_json
    new_pin = Pin.find_by(id: id)
    if new_pin.nil?
      status = add_status_to_new_pin(action_button)
      pin = Pin.create(company_id: company_id, name: name, definition: definition_to_preset, status: status, ui_definition: ui_definition)
    elsif  action_button == GENERATE
      delete_pin(new_pin.id)
      status = :pre_create_pin
      pin = Pin.create(company_id: company_id, name: name, definition: definition_to_preset, status: status, ui_definition: ui_definition)
    else
      pin = Pin.where(id: new_pin.id).first
      status = :draft
      pin.update_attributes(company_id: company_id, name: name, definition: definition_to_preset, status: status, ui_definition: ui_definition) unless  pin.nil?
    end
    render json: { preset: pin.pack_to_json }
  end

  def rename
    authorize :pin, :update?
    name = params[:name]
    id = params[:id]
    pin = Pin.find(id)
    pin.update(name: name) if pin
    render json: {}
  end

  def delete
    authorize :pin, :delete?
    id = params[:id].to_i
    res = delete_pin(id)
    render json: { message: res }
  end

  def show
    authorize :pin, :index?
    res = {}
    pins_arr = pinscope
    res[:drafts] = create_preset_status_list(pins_arr.draft)
    res[:in_progress] = create_preset_status_list(pins_arr.pre_create_pin + pins_arr.priority + pins_arr.in_progress)
    res[:active] = create_preset_status_list(pins_arr.saved)
    render json: res
  end

  def show_preset_employess
    authorize :pin, :index?
    pid = params[:pid].to_i
    res = EmployeesPin.where(pin_id: pid).pluck(:employee_id)
    render json: res
  end

  def filters
    emp_enums = EmployeeEnumeration.all.where(company_id: params[:company_id])
    render json: emp_enums.pack_to_json
  end

  private

  def create_preset_status_list(preset_list)
    res = []
    preset_list.each do |e|
      preset = e.pack_to_json
      res << preset
    end
    return res
  end

  def pinscope
    PinPolicy::Scope.new(current_user, Pin).resolve
  end

  def pin_params
    params.require(:pin).permit(*policy(@pin || Pin).permitted_attributes)
  end
end
