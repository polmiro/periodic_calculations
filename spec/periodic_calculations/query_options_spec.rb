describe PeriodicCalculations::QueryOptions do

  it "initializes without errors when valid parameters" do
    time = DateTime.now
    query_options = described_class.new(time, time)
    query_options.window_start.should == time
  end

  describe "raises ArgumentError when" do
    it "no window start" do
      expect {
        described_class.new(nil, DateTime.now)
      }.to raise_error(ArgumentError)
    end

    it "no window end" do
      expect {
        described_class.new(DateTime.now, nil)
      }.to raise_error(ArgumentError)
    end

    it "window start is not a DateTime" do
      expect {
        described_class.new(3, DateTime.now)
      }.to raise_error(ArgumentError)
    end

    it "window end is not a DateTime" do
      expect {
        described_class.new(DateTime.now, 3)
      }.to raise_error(ArgumentError)
    end

    it "interval_unit is not valid" do
      expect {
        described_class.new(DateTime.now, DateTime.now, :interval_unit => '3days')
      }.to raise_error(ArgumentError)
    end
  end

  describe "defaults" do
    let(:query_options) do
      time = DateTime.now
      described_class.new(time, time)
    end

    it "interval_unit to :day" do
      query_options.interval_unit.should == :day
    end

    it "cumulative to false" do
      query_options.cumulative.should be_false
    end

    it "timezone_offset to Rails timezone offset in seconds" do
      query_options.timezone_offset.should == Time.now.in_time_zone.utc_offset
    end
  end

end