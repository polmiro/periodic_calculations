require 'spec_helper'

describe CountDuring::Query do

  before { Activity.delete_all }

  let(:scope) { Activity.all }
  let(:time) { Time.now }

  let(:options) do
    {
      :start_time => time - 1.day,
      :end_time => time + 1.day,
      :interval_unit => :day,
      :cumulative => false
    }
  end

  it "should add missing values within range" do
    scope.count_during(options).should have(3).items
  end

  it "should return one single day when same dates" do
    options.merge!(
      :start_time => time,
      :end_time => time
    )

    scope.count_during(options).should have(1).items
  end

  it "should return two day when consecutive" do
    options.merge!(
      :start_time => time,
      :end_time => time + 1.day
    )

    scope.count_during(options).should have(2).items
  end

  it "should count by day" do
    options.merge!(
      :interval_unit => :day,
      :start_time => time,
      :end_time => time + 2.day
    )

    scope.count_during(options).should have(3).items
  end

  it "should count by week" do
    options.merge!(
      :interval_unit => :week,
      :start_time => time,
      :end_time => time + 1.week
    )

    scope.count_during(options).should have(2).items
  end

  it "should count by month" do
    options.merge!(
      :interval_unit => :month,
      :start_time => time,
      :end_time => time + 4.months
    )

    scope.count_during(options).should have(4).items
  end

  it "should consider rows outside current scope" do
    Activity.create(:quantity => 3, :created_at => time)
    new_scope = scope.where(:quantity => 3)
    new_scope.count_during(options).map(&:last).should == [0, 1, 0]
  end

  it "should NOT consider rows outside current scope" do
    Activity.create(:quantity => 0, :created_at => time)
    new_scope = scope.where(:quantity => 3)
    new_scope.count_during(options).map(&:last).should == [0, 0, 0]
  end

  context "when cumulative count" do
    before { options.merge!(:cumulative => true) }

    it "should count cumulatively" do
      Activity.create(:created_at => time - 1.day)
      Activity.create(:created_at => time)
      Activity.create(:created_at => time + 1.day)
      scope.count_during(options).map(&:last).should == [1, 2, 3]
    end

    it "should accumulate counts outside of the interval" do
      Activity.create(:created_at => time - 10.day)
      Activity.create(:created_at => time)
      scope.count_during(options).map(&:last).should == [1, 2, 2]
    end
  end

  context "when non-cumulative count" do
    it "should count only the interval unit" do
      Activity.create(:created_at => time - 10.day)
      Activity.create(:created_at => time)
      scope.count_during(options).map(&:last).should == [0, 1, 0]
    end
  end
end