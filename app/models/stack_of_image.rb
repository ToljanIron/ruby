class StackOfImage < ActiveRecord::Base
  MALE = 0
  FEMALE = 1
  def self.random_image(employee)
    return random_male_image if employee.try(:male?)
    return random_female_image if employee.try(:female?)
    StackOfImage.all.sample.img_name
  end

  def self.random_male_image
    return StackOfImage.where(gender: MALE).sample.img_name
  end

  def self.random_female_image
    return StackOfImage.where(gender: FEMALE).sample.img_name
  end
end
