describe "Model" do

  before { Activity.delete_all }

  let(:klass) { Activity }
  let(:model) { klass.new }

  it "has a class method .periodic_calculation" do
    klass.should respond_to(:periodic_calculation)
  end

  describe ".periodic_count" do
    it "calculates a periodic count operation" do
      klass.should_receive(:periodic_calculation).with(:count, :args).once.and_return(true)
      klass.periodic_count(:args)
    end
  end

  describe ".periodic_maximum" do
    it "calculates a periodic maximum operation" do
      klass.should_receive(:periodic_calculation).with(:max, :args).once.and_return(true)
      klass.periodic_maximum(:args)
    end
  end

  describe ".periodic_minimum" do
    it "calculates a periodic minimum operation" do
      klass.should_receive(:periodic_calculation).with(:min, :args).once.and_return(true)
      klass.periodic_minimum(:args)
    end
  end

  describe ".periodic_sum" do
    it "calculates a periodic sum operation" do
      klass.should_receive(:periodic_calculation).with(:sum, :args).once.and_return(true)
      klass.periodic_sum(:args)
    end
  end

  describe ".periodic_average" do
    it "calculates a periodic average operation" do
      klass.should_receive(:periodic_calculation).with(:avg, :args).once.and_return(true)
      klass.periodic_average(:args)
    end
  end

  describe ".periodic_calculation" do
    before do
      result = double(:execute => true)
      PeriodicCalculations::Query.stub(:new).and_return(result)
    end

    let(:operation) { :count }
    let(:column_name) { :id }
    let(:start_time) { DateTime.now - 1.day }
    let(:end_time) { DateTime.now + 1.day }
    let(:options) do
      {
        :cumulative => true,
        :interval_unit => :month
      }
    end

    it "builts the correct PeriodicCalculations::QueryOptions" do
      PeriodicCalculations::QueryOptions
        .should_receive(:new)
        .with(operation, column_name, start_time, end_time, options)
        .once

      klass.periodic_calculation(operation, column_name, start_time, end_time, options)
    end

    it "executes a Query with an instance of PeriodicCalculations::QueryOptions" do
      PeriodicCalculations::Query
        .should_receive(:new)
        .with(klass.all, an_instance_of(PeriodicCalculations::QueryOptions))
        .once

      klass.periodic_calculation(operation, column_name, start_time, end_time, options)
    end
  end
end