describe TestModel do

  before { clean_database }

  let(:klass) { TestModel }
  let(:model) { klass.new }

  it "has a class method .count_during" do
    klass.should respond_to(:count_during)
  end

  describe ".count_during" do
    let(:options) do
      {
        :start_time => Time.now - 1.day,
        :end_time => Time.now + 1.day,
        :cumulative => true,
        :interval_unit => :day
      }
    end

    it "executes a Query with the correct parameters" do
      CountDuring::Query.should_receive(:new).with(klass.all, options).and_return(double(:execute => true))
      klass.count_during(options)
    end
  end
end