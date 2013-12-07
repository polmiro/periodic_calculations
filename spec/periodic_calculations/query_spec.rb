require 'spec_helper'

describe PeriodicCalculations::Query do

  before { Activity.delete_all }

  let(:scope) { Activity.all }
  let(:time) { DateTime.now }

  let(:operation) { :count }
  let(:column_name) { :id }
  let(:start_time) { time - 1.day }
  let(:end_time) { time + 1.day }
  let(:options) { {} }

  describe "#execute" do

    def execute(scope, *args)
      query_options = PeriodicCalculations::QueryOptions.new(*args)
      PeriodicCalculations::Query.new(scope, query_options).execute
    end

    it "should add missing values within range" do
      execute(scope, operation, column_name, start_time, end_time, options).should have(3).items
    end

    it "should return one single day when same dates" do
      start_time = time
      end_time = time

      execute(scope, operation, column_name, start_time, end_time, options).should have(1).items
    end

    it "should return two day when consecutive" do
      start_time = time
      end_time = time + 1.day

      execute(scope, operation, column_name, start_time, end_time, options).should have(2).items
    end

    it "should operate by day" do
      start_time = time
      end_time = time + 2.day
      options.merge!(:interval_unit => :day)

      execute(scope, operation, column_name, start_time, end_time, options).should have(3).items
    end

    it "should operate by week" do
      start_time = time
      end_time = time + 1.week
      options.merge!(:interval_unit => :week)

      execute(scope, operation, column_name, start_time, end_time, options).should have(2).items
    end

    it "should operate by month" do
      start_time = time
      end_time = time + 4.months
      options.merge!(:interval_unit => :month)

      execute(scope, operation, column_name, start_time, end_time, options).should have(5).items
    end

    it "should operate counts" do
      Activity.create(:quantity => 3, :created_at => time)
      execute(scope, :count, column_name, start_time, end_time, options).map(&:last).should == [0, 1, 0]
    end

    it "should consider rows outside current scope" do
      Activity.create(:quantity => 3, :created_at => time)
      scope = Activity.where(:quantity => 3)

      execute(scope, operation, column_name, start_time, end_time, options).map(&:last).should == [0, 1, 0]
    end

    it "should NOT consider rows outside current scope" do
      Activity.create(:quantity => 0, :created_at => time)
      scope = Activity.where(:quantity => 3)

      execute(scope, operation, column_name, start_time, end_time, options).map(&:last).should == [0, 0, 0]
    end

    describe "count" do
       it "should count NON cumulatively" do
        Activity.create(:created_at => time - 10.day)
        Activity.create(:created_at => time)

        execute(scope, operation, column_name, start_time, end_time, options).map(&:last).should == [0, 1, 0]
      end

      it "should count cumulatively" do
        options[:cumulative] = true

        # outside interval matters
        Activity.create(:created_at => time - 10.day)

        Activity.create(:created_at => time - 1.day)
        Activity.create(:created_at => time)
        Activity.create(:created_at => time + 1.day)

        execute(scope, operation, column_name, start_time, end_time, options).map(&:last).should == [2, 3, 4]
      end
    end

    describe "average" do
      it "should calculate the average cumulatively" do
        Activity.create(:quantity => 4, :created_at => time)
        Activity.create(:quantity => 8, :created_at => time)

        execute(scope, :avg, :quantity, start_time, end_time, options).map(&:last).should == [0, 6, 0]
      end

      it "should calculate the average NON cumulatively" do
        Activity.create(:quantity => 4, :created_at => time - 10.days)
        Activity.create(:quantity => 8, :created_at => time)

        options[:cumulative] = true

        execute(scope, :avg, :quantity, start_time, end_time, options).map(&:last).should == [4, 6, 6]
      end
    end

    describe "sum" do
      it "should calculate the sum NON cumulatively" do
        Activity.create(:quantity => 4, :created_at => time)
        Activity.create(:quantity => 8, :created_at => time)

        execute(scope, :sum, :quantity, start_time, end_time, options).map(&:last).should == [0, 12, 0]
      end

      it "should calculate the sum cumulatively" do
        options[:cumulative] = true

        Activity.create(:quantity => 4, :created_at => time - 10.days)
        Activity.create(:quantity => 8, :created_at => time)

        execute(scope, :sum, :quantity, start_time, end_time, options).map(&:last).should == [4, 12, 12]
      end
    end

    describe "minimum" do
      it "should calculate the minimum no cumulatively" do
        Activity.create(:quantity => 4, :created_at => time)
        Activity.create(:quantity => 8, :created_at => time)

        execute(scope, :min, :quantity, start_time, end_time, options).map(&:last).should == [0, 4, 0]
      end

      it "should calculate the minimum cumulatively" do
        options[:cumulative] = true

        Activity.create(:quantity => 8, :created_at => time - 10.days)
        Activity.create(:quantity => 4, :created_at => time)

        execute(scope, :min, :quantity, start_time, end_time, options).map(&:last).should == [8, 4, 4]
      end
    end

    describe "maximum" do
      it "should calculate the maximum NON cumulatively" do
        Activity.create(:quantity => 4, :created_at => time)
        Activity.create(:quantity => 8, :created_at => time)

        execute(scope, :max, :quantity, start_time, end_time, options).map(&:last).should == [0, 8, 0]
      end

      it "should calculate the maximum cumulatively" do
        options[:cumulative] = true

        Activity.create(:quantity => 4, :created_at => time - 10.days)
        Activity.create(:quantity => 8, :created_at => time)

        execute(scope, :max, :quantity, start_time, end_time, options).map(&:last).should == [4, 8, 8]
      end
    end

  end
end