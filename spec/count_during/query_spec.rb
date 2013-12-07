require 'spec_helper'

describe CountDuring::Query do

  before { Activity.delete_all }

  let(:scope) { Activity.all }
  let(:time) { Time.now }

  let(:start_time) { time - 1.day }
  let(:end_time) { time + 1.day }
  let(:options) { {} }

  describe "#execute" do

    def execute(*args)
      CountDuring::Query.new(*args).execute
    end

    it "should add missing values within range" do
      execute(scope, start_time, end_time, options).should have(3).items
    end

    it "should return one single day when same dates" do
      start_time = time
      end_time = time

      execute(scope, start_time, end_time, options).should have(1).items
    end

    it "should return two day when consecutive" do
      start_time = time
      end_time = time + 1.day

      execute(scope, start_time, end_time, options).should have(2).items
    end

    it "should count by day" do
      start_time = time
      end_time = time + 2.day
      options.merge!(:interval_unit => :day)

      execute(scope, start_time, end_time, options).should have(3).items
    end

    it "should count by week" do
      start_time = time
      end_time = time + 1.week
      options.merge!(:interval_unit => :week)

      execute(scope, start_time, end_time, options).should have(2).items
    end

    it "should count by month" do
      start_time = time
      end_time = time + 4.months
      options.merge!(:interval_unit => :month)

      execute(scope, start_time, end_time, options).should have(4).items
    end

    it "should consider rows outside current scope" do
      Activity.create(:quantity => 3, :created_at => time)
      scope = Activity.where(:quantity => 3)

      execute(scope, start_time, end_time, options).map(&:last).should == [0, 1, 0]
    end

    it "should NOT consider rows outside current scope" do
      Activity.create(:quantity => 0, :created_at => time)
      scope = Activity.where(:quantity => 3)

      execute(scope, start_time, end_time, options).map(&:last).should == [0, 0, 0]
    end

    context "when cumulative count" do
      before { options.merge!(:cumulative => true) }

      it "should count cumulatively" do
        Activity.create(:created_at => time - 1.day)
        Activity.create(:created_at => time)
        Activity.create(:created_at => time + 1.day)

        execute(scope, start_time, end_time, options).map(&:last).should == [1, 2, 3]
      end

      it "should accumulate counts outside of the interval" do
        Activity.create(:created_at => time - 10.day)
        Activity.create(:created_at => time)

        execute(scope, start_time, end_time, options).map(&:last).should == [1, 2, 2]
      end
    end

    context "when non-cumulative count" do
      it "should count only the interval unit" do
        Activity.create(:created_at => time - 10.day)
        Activity.create(:created_at => time)

        execute(scope, start_time, end_time, options).map(&:last).should == [0, 1, 0]
      end
    end

  end
end