FactoryGirl.define do
  factory :chart do
    name 'Test Chart'
    is_template false
    association :organization
  end

  factory :chart_with_sections, :parent => :chart do
    after(:create) do |chart|
      2.times do
        chart.sections << FactoryGirl.create(:section)
      end
    end
  end

  factory :chart_with_free_sections, :parent => :chart do
    after(:create) do |chart|
      2.times do
        chart.sections << FactoryGirl.create(:free_section)
      end
    end
  end

  factory :assigned_chart, :parent => :chart_with_sections do
    association :event
  end

  factory :chart_template, :parent => :chart do
    is_template true
  end
end