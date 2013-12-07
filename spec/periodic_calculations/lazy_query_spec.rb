describe PeriodicCalculations::LazyQuery do

  let(:query) { double }
  let(:lazy_query) { described_class.new(query)}

  it "loads the result only once" do
    query.should_receive(:execute).once.and_return nil
    lazy_query.result
    lazy_query.result
  end

  it "delegates to_sql method to the query object" do
    query.should_receive(:to_sql).once.and_return nil
    lazy_query.to_sql
  end

  it "delegates all other methods to the result set" do
    result = double
    query.should_receive(:execute).once.and_return result
    result.should_receive(:my_method).once.and_return(true)
    lazy_query.my_method
  end

  it "responds to result" do
    lazy_query.should respond_to(:result)
  end

  it "responds to to_sql" do
    lazy_query.should respond_to(:to_sql)
  end

  it "responds to methods the result object responds to" do
    result = double(:respond_to? => true)
    query.should_receive(:execute).once.and_return result
    result.should_receive(:my_method).once.and_return(true)
    lazy_query.my_method
  end
end