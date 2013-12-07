describe "Model" do

  before { Activity.delete_all }

  let(:klass) { Activity }
  let(:model) { klass.new }

  it "has a class method .count_during" do
    klass.should respond_to(:count_during)
  end

  describe ".count_during" do
    let(:start_time) { Time.now - 1.day }
    let(:end_time) { Time.now + 1.day }
    let(:options) do
      {
        :cumulative => true,
        :interval_unit => :month
      }
    end

    it "executes a Query with the correct parameters" do
      result = double(:execute => true)

      CountDuring::Query
        .should_receive(:new)
        .with(klass.all, start_time, end_time, options)
        .once
        .and_return(result)

      klass.count_during(start_time, end_time, options)
    end
  end
end