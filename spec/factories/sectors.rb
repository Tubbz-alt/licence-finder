# Read about factories at https://github.com/thoughtbot/factory_girl

FactoryGirl.define do
  factory :sector do
    sequence(:public_id)
    sequence(:correlation_id)
    name "Test Sector"
  end
end
