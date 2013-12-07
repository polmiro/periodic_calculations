describe "Model" do

  before { Activity.delete_all }

  let(:klass) { Activity }
  let(:model) { klass.new }

  it "has a class method .count_during" do
    klass.should respond_to(:count_during)
  end

  describe ".count_during" do
    before do
      result = double(:execute => true)
      CountDuring::Query.stub(:new).and_return(result)
    end

    let(:start_time) { DateTime.now - 1.day }
    let(:end_time) { DateTime.now + 1.day }
    let(:options) do
      {
        :cumulative => true,
        :interval_unit => :month
      }
    end

    it "builts the correct CountDuring::QueryOptions" do
      CountDuring::QueryOptions
        .should_receive(:new)
        .with(start_time, end_time, options)
        .once

      klass.count_during(start_time, end_time, options)
    end

    it "executes a Query with an instance of CountDuring::QueryOptions" do
      CountDuring::Query
        .should_receive(:new)
        .with(klass.all, an_instance_of(CountDuring::QueryOptions))
        .once

      klass.count_during(start_time, end_time, options)
    end
  end
end