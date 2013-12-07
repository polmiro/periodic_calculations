describe PeriodicCalculations::QueryOptions do

  it "initializes without errors when valid parameters" do
    time = DateTime.now
    query_options = described_class.new(:count, :id, time, time)
    query_options.window_start.should == time
  end

  describe "raises ArgumentError when" do
    it "no operation" do
      expect {
        described_class.new(nil, :id, DateTime.now, DateTime.now)
      }.to raise_error(ArgumentError)
    end

    it "invalid operation" do
      expect {
        described_class.new(:xxx, :id, DateTime.now, DateTime.now)
      }.to raise_error(ArgumentError)
    end

    it "no column_name" do
      expect {
        described_class.new(nil, nil, DateTime.now, DateTime.now)
      }.to raise_error(ArgumentError)
    end

    it "no window start" do
      expect {
        described_class.new(:count, :id, nil, DateTime.now)
      }.to raise_error(ArgumentError)
    end

    it "no window end" do
      expect {
        described_class.new(:count, :id, DateTime.now, nil)
      }.to raise_error(ArgumentError)
    end

    it "window start is not a DateTime" do
      expect {
        described_class.new(:count, :id, 3, DateTime.now)
      }.to raise_error(ArgumentError)
    end

    it "window end is not a DateTime" do
      expect {
        described_class.new(:count, :id, DateTime.now, 3)
      }.to raise_error(ArgumentError)
    end

    it "interval_unit is not valid" do
      expect {
        described_class.new(:count, :id, DateTime.now, DateTime.now, :interval_unit => '3days')
      }.to raise_error(ArgumentError)
    end
  end

  describe "defaults" do
    let(:query_options) do
      time = DateTime.now
      described_class.new(:count, :id, time, time)
    end

    it "timestamp_column to :created_at" do
      query_options.timestamp_column.should == :created_at
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