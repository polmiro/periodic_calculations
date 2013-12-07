require 'spec_helper'

describe CountDuring::Query do

  before { clean_database }

  let(:scope) { TestModel.all }
  let(:time) { Time.now }

  let(:options) do
    {
      :start_time => time - 1.day,
      :end_time => time + 1.day,
      :interval_unit => :day,
      :cumulative => false
    }
  end

  it "should return one single day when same dates" do
    result = scope.count_during(options.merge(:start_time => time, :end_time => time))
    result.should have(1).items
  end

  it "should return two day when consecutive" do
    result = scope.count_during(options.merge(:start_time => time, :end_time => time + 1.day))
    result.should have(2).items
  end

  it "should count by day" do
    result = scope.count_during(options)
    result.should have(3).items
  end

  it "should count by week" do
    result = scope.count_during(options.merge(:interval_unit => :week))
    result.should have(3).items
  end

  it "should count by month" do
    result = scope.count_during(options.merge(:interval_unit => :month))
    result.should have(3).items
  end

  it "should add missing values within range" do
    result = scope.count_during(options)
    result.should have(3).items
  end

  it "should consider rows in current scope" do
    scope.where(:number => 999).count_during(options).should be_empty
  end

  context "when cumulative count" do
    it "should count cumulatively" do
      model = TestModel.create
      model.update_attribute(:created_at, time - 1.day)

      model = TestModel.create
      model.update_attribute(:created_at, time)

      model = TestModel.create
      model.update_attribute(:created_at, time + 1.day)

      result = scope.count_during(options.merge(:cumulative => true))
      result.values.should == [1, 2, 3]
    end
  end

  context "when non-cumulative count" do
    it "should count only the interval unit" do
      TestModel.create
      TestModel.create

      result = scope.count_during(options)
      result.values.should == [0, 1, 0]
    end
  end
end